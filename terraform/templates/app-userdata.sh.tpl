#!/bin/bash
# ASG bootstrap: new app boxes self-heal (Docker + last CD image tag).
set -euxo pipefail
exec > >(tee /var/log/uncooked-bootstrap.log) 2>&1

echo "role=app" > /etc/uncooked-role

export DEBIAN_FRONTEND=noninteractive
export AWS_REGION="${aws_region}"
export ECR_REGISTRY="${ecr_registry}"
export DATA_HOST="${data_host}"

if ! command -v docker >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y ca-certificates curl gnupg unzip
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  systemctl enable --now docker
fi

if ! command -v aws >/dev/null 2>&1; then
  cd /tmp
  curl -fsSLo awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
  unzip -qo awscliv2.zip
  ./aws/install --update
fi

# Wait for CD to have published a tag (first boot / fresh account).
IMAGE_TAG=""
for _ in $(seq 1 60); do
  IMAGE_TAG=$(aws ssm get-parameter --name /uncooked/app/image_tag --region "$AWS_REGION" --query Parameter.Value --output text 2>/dev/null || true)
  if [[ -n "$IMAGE_TAG" && "$IMAGE_TAG" != "None" ]]; then
    break
  fi
  sleep 10
done
if [[ -z "$IMAGE_TAG" || "$IMAGE_TAG" == "None" ]]; then
  echo "No /uncooked/app/image_tag yet — skip app start (CD must push first)"
  exit 0
fi

JWT_PRIV=$(aws ssm get-parameter --name /uncooked/app/jwt_private_key --with-decryption --region "$AWS_REGION" --query Parameter.Value --output text)
JWT_PUB=$(aws ssm get-parameter --name /uncooked/app/jwt_public_key --with-decryption --region "$AWS_REGION" --query Parameter.Value --output text)

mkdir -p /opt/uncooked/backend /opt/uncooked/agent
cd /opt/uncooked
printf '%s' '${compose_b64}' | base64 -d > docker-compose.app.yml

aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"

TOKEN=$(curl -fsS -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" || true)
SERVER_IP=$(curl -fsS -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4 || hostname -I | awk '{print $1}')

cat > .env <<ENVEOF
DATA_HOST=$DATA_HOST
ECR_FRONTEND_IMAGE=$ECR_REGISTRY/uncooked-frontend:$IMAGE_TAG
ECR_BACKEND_IMAGE=$ECR_REGISTRY/uncooked-backend:$IMAGE_TAG
ECR_AGENT_IMAGE=$ECR_REGISTRY/uncooked-agent:$IMAGE_TAG
SERVER_IP=$SERVER_IP
REDIS_PASSWORD=123123123
RABBITMQ_USER=admin123
RABBITMQ_PASSWORD=123123123
RABBITMQ_VHOST=hackathon
ENVEOF

umask 077
{
  printf 'JWT_PRIVATE_KEY=%s\n' "$JWT_PRIV"
  printf 'JWT_PUBLIC_KEY=%s\n' "$JWT_PUB"
} > backend/.env
touch agent/.env

docker compose -f docker-compose.app.yml --env-file .env up -d --pull always
docker compose -f docker-compose.app.yml ps
echo "bootstrap ok tag=$IMAGE_TAG"
