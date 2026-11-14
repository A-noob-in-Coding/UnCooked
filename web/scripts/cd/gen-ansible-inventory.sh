#!/usr/bin/env bash
# Write ansible/inventory/hosts.yml from the live data EC2 + ASG.
set -euo pipefail

: "${AWS_REGION:=ap-south-1}"
: "${ASG_NAME:=uncooked-app-asg}"
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
OUT="${ROOT}/ansible/inventory/hosts.yml"

DATA_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Role,Values=data" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text)

if [[ -z "$DATA_ID" || "$DATA_ID" == "None" ]]; then
  echo "no running data instance (tag Role=data)"
  exit 1
fi

APP_IDS=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "$ASG_NAME" \
  --query "AutoScalingGroups[0].Instances[?LifecycleState=='InService'].InstanceId" \
  --output text)

{
  echo "all:"
  echo "  children:"
  echo "    data:"
  echo "      hosts:"
  echo "        data1:"
  echo "          ansible_host: $DATA_ID"
  echo "          ansible_connection: aws_ssm"
  echo "          ansible_aws_ssm_region: $AWS_REGION"
  echo "    app:"
  echo "      hosts:"
  i=1
  for id in $APP_IDS; do
    echo "        app$i:"
    echo "          ansible_host: $id"
    echo "          ansible_connection: aws_ssm"
    echo "          ansible_aws_ssm_region: $AWS_REGION"
    i=$((i + 1))
  done
  echo "  vars:"
  echo "    project_name: uncooked"
  echo "    aws_region: $AWS_REGION"
  echo "    deploy_dir: /opt/uncooked"
} > "$OUT"

echo "wrote $OUT"
