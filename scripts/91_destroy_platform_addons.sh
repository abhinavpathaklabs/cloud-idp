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

# Destroy Helm/K8s resources first (only these targets)
terraform destroy -auto-approve \
  -target=helm_release.metrics_server \
  -target=helm_release.external_secrets \
  -target=helm_release.aws_load_balancer_controller || true
