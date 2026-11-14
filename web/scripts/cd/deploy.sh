#!/usr/bin/env bash
# Deploy IMAGE_TAG to InService ASG instances via SSM.
set -euo pipefail

: "${IMAGE_TAG:?}"
: "${ASG_NAME:?}"
: "${DATA_HOST:?}"
: "${ECR_REGISTRY:?}"
: "${AWS_REGION:=ap-south-1}"

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
COMPOSE_FILE="${ROOT}/web/docker-compose.app.yml"
test -f "$COMPOSE_FILE"

echo "Looking up instances in $ASG_NAME"
INSTANCE_IDS=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "$ASG_NAME" \
  --query "AutoScalingGroups[0].Instances[?LifecycleState=='InService'].InstanceId" \
  --output text)

if [[ -z "${INSTANCE_IDS// /}" ]]; then
  echo "No InService instances in $ASG_NAME"
  exit 1
fi

echo "Targets: $INSTANCE_IDS"
echo "$IMAGE_TAG" > /tmp/uncooked-new-tag

PREV=$(aws ssm get-parameter --name "/uncooked/app/image_tag" --query Parameter.Value --output text 2>/dev/null || true)
if [[ -n "${PREV}" && "${PREV}" != "None" ]]; then
  echo "$PREV" > /tmp/uncooked-previous-tag
  echo "Previous tag: $PREV"
fi

if base64 --help 2>&1 | grep -q -- '-w'; then
  COMPOSE_B64=$(base64 -w0 "$COMPOSE_FILE")
else
  COMPOSE_B64=$(base64 < "$COMPOSE_FILE" | tr -d '\n')
fi

# Pull JWT on the runner (GHA role / local AWS), then ship into backend/.env on the box.
JWT_PRIV=$(aws ssm get-parameter --name /uncooked/app/jwt_private_key --with-decryption --query Parameter.Value --output text --region "$AWS_REGION" 2>/dev/null || true)
JWT_PUB=$(aws ssm get-parameter --name /uncooked/app/jwt_public_key --with-decryption --query Parameter.Value --output text --region "$AWS_REGION" 2>/dev/null || true)
if [[ -z "$JWT_PRIV" || -z "$JWT_PUB" || "$JWT_PRIV" == "None" || "$JWT_PUB" == "None" ]]; then
  echo "Missing SSM JWT params /uncooked/app/jwt_private_key and jwt_public_key"
  exit 1
fi

DEPLOY_SCRIPT=$(cat <<EOF
set -euo pipefail
mkdir -p /opt/uncooked/backend /opt/uncooked/agent
cd /opt/uncooked
printf '%s' '${COMPOSE_B64}' | base64 -d > docker-compose.app.yml
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
printf '%s\n' \
  'DATA_HOST=${DATA_HOST}' \
  'ECR_FRONTEND_IMAGE=${ECR_REGISTRY}/uncooked-frontend:${IMAGE_TAG}' \
  'ECR_BACKEND_IMAGE=${ECR_REGISTRY}/uncooked-backend:${IMAGE_TAG}' \
  'ECR_AGENT_IMAGE=${ECR_REGISTRY}/uncooked-agent:${IMAGE_TAG}' \
  'REDIS_PASSWORD=123123123' \
  'RABBITMQ_USER=admin123' \
  'RABBITMQ_PASSWORD=123123123' \
  'RABBITMQ_VHOST=hackathon' > .env
printf '%s\n' 'JWT_PRIVATE_KEY=${JWT_PRIV}' 'JWT_PUBLIC_KEY=${JWT_PUB}' > backend/.env
touch agent/.env
docker compose -f docker-compose.app.yml --env-file .env up -d --pull always
EOF
)
DEPLOY_B64=$(printf '%s' "$DEPLOY_SCRIPT" | if base64 --help 2>&1 | grep -q -- '-w'; then base64 -w0; else base64 | tr -d '\n'; fi)

PARAMS=$(jq -nc --arg b64 "$DEPLOY_B64" '{ commands: ["echo " + $b64 + " | base64 -d | bash"] }')

CMD_ID=$(aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --instance-ids $INSTANCE_IDS \
  --parameters "$PARAMS" \
  --query Command.CommandId \
  --output text)

echo "SSM command: $CMD_ID"

FAIL=0
for id in $INSTANCE_IDS; do
  aws ssm wait command-executed --command-id "$CMD_ID" --instance-id "$id" || true
  STATUS=$(aws ssm get-command-invocation \
    --command-id "$CMD_ID" \
    --instance-id "$id" \
    --query Status \
    --output text)
  echo "$id => $STATUS"
  if [[ "$STATUS" != "Success" ]]; then
    aws ssm get-command-invocation --command-id "$CMD_ID" --instance-id "$id" --query StandardErrorContent --output text || true
    FAIL=1
  fi
done

[[ "$FAIL" -eq 0 ]] || exit 1

aws ssm put-parameter \
  --name "/uncooked/app/image_tag" \
  --type String \
  --value "$IMAGE_TAG" \
  --overwrite >/dev/null

echo "Deployed $IMAGE_TAG"
