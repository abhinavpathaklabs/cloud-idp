#!/usr/bin/env bash
set -euo pipefail

: "${TF_STATE_BUCKET:?}"
: "${TF_LOCK_TABLE:?}"

cd infra/terraform/platform

terraform init -reconfigure \
  -backend-config="bucket=${TF_STATE_BUCKET}" \
  -backend-config="dynamodb_table=${TF_LOCK_TABLE}" \
  -backend-config="region=us-east-1" \
  -backend-config="key=platform/dev/terraform.tfstate"

# Full destroy (after services + addons are gone)
terraform destroy -auto-approve
