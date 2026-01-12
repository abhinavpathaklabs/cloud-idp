#!/usr/bin/env bash
set -euo pipefail

cd infra/terraform/bootstrap
terraform init
terraform destroy -auto-approve
