#!/usr/bin/env bash
set -euo pipefail

# Fill these from bootstrap outputs
TF_STATE_BUCKET="${TF_STATE_BUCKET:?set TF_STATE_BUCKET}"
TF_LOCK_TABLE="${TF_LOCK_TABLE:?set TF_LOCK_TABLE}"

cd infra/terraform/platform
terraform init -reconfigure \
  -backend-config="bucket=${TF_STATE_BUCKET}" \
  -backend-config="dynamodb_table=${TF_LOCK_TABLE}" \
  -backend-config="region=us-east-1" \
  -backend-config="key=platform/dev/terraform.tfstate"

terraform apply -auto-approve \
  -var="tf_state_bucket=${TF_STATE_BUCKET}" \
  -var="tf_lock_table=${TF_LOCK_TABLE}" \
  -var="allowed_cidr=${ALLOWED_CIDR:?set ALLOWED_CIDR like 1.2.3.4/32}" \
  -var="ssh_public_key=${SSH_PUBLIC_KEY:?set SSH_PUBLIC_KEY content}" \
  -var="repo_url=${REPO_URL:?set REPO_URL}" \
  -var="repo_branch=${REPO_BRANCH:-main}"

echo ""
echo "Jenkins URL:"
terraform output -raw jenkins_url
echo "Admin password:"
terraform output -raw jenkins_admin_password
