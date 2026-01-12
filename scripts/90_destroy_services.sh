#!/usr/bin/env bash
set -euo pipefail

: "${TF_STATE_BUCKET:?}"
: "${TF_LOCK_TABLE:?}"
: "${AWS_REGION:=us-east-1}"
: "${PROJECT:=cloud-idp}"
: "${ENV:=dev}"

# List all service state files in S3
echo "Listing service states in s3://${TF_STATE_BUCKET}/services/${ENV}/ ..."
KEYS=$(aws s3api list-objects-v2 \
  --bucket "$TF_STATE_BUCKET" \
  --prefix "services/${ENV}/" \
  --query 'Contents[].Key' \
  --output text || true)

if [[ -z "${KEYS// }" ]]; then
  echo "No service states found. Skipping."
  exit 0
fi

for KEY in $KEYS; do
  SERVICE=$(basename "$KEY" .tfstate)
  echo ""
  echo "Destroying service env: $SERVICE (state key: $KEY)"

  pushd infra/terraform/service-env >/dev/null
  terraform init -reconfigure \
    -backend-config="bucket=${TF_STATE_BUCKET}" \
    -backend-config="dynamodb_table=${TF_LOCK_TABLE}" \
    -backend-config="region=${AWS_REGION}" \
    -backend-config="key=${KEY}"

  terraform destroy -auto-approve \
    -var="region=${AWS_REGION}" \
    -var="project=${PROJECT}" \
    -var="env=${ENV}" \
    -var="service_name=${SERVICE}"
  popd >/dev/null
done

echo ""
echo "All service environments destroyed."
