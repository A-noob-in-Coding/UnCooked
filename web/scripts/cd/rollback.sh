#!/usr/bin/env bash
# Redeploy a previous image tag (manual or auto after failed smoke).
set -euo pipefail

: "${ASG_NAME:?}"
: "${DATA_HOST:?}"
: "${ECR_REGISTRY:?}"
: "${AWS_REGION:=ap-south-1}"

# Prefer explicit IMAGE_TAG (workflow input), then file from failed deploy, then SSM.
if [[ -z "${IMAGE_TAG:-}" ]]; then
  if [[ -f /tmp/uncooked-previous-tag ]]; then
    IMAGE_TAG=$(cat /tmp/uncooked-previous-tag)
  else
    IMAGE_TAG=$(aws ssm get-parameter --name "/uncooked/app/image_tag" --query Parameter.Value --output text 2>/dev/null || true)
  fi
fi

if [[ -z "${IMAGE_TAG}" || "${IMAGE_TAG}" == "None" ]]; then
  echo "no previous tag to roll back to"
  exit 1
fi

echo "rolling back to $IMAGE_TAG"
export IMAGE_TAG
bash "$(dirname "$0")/deploy.sh"
