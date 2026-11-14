#!/usr/bin/env bash
# Print secret/vars to paste into GitHub Actions.
set -euo pipefail
cd "$(dirname "$0")/../../../terraform"

echo "secret:"
echo "  AWS_ROLE_ARN=$(terraform output -raw github_actions_role_arn)"
echo
echo "variables:"
echo "  AWS_REGION=$(terraform output -raw aws_region)"
echo "  ALB_URL=$(terraform output -raw alb_url)"
echo "  ASG_NAME=$(terraform output -raw asg_name)"
echo "  DATA_HOST=$(terraform output -raw data_private_ip)"
URL=$(terraform output -json ecr_repository_urls | jq -r '.frontend')
echo "  ECR_REGISTRY=${URL%%/*}"
