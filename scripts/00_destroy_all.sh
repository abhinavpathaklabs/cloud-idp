#!/usr/bin/env bash
set -euo pipefail

export AWS_REGION="${AWS_REGION:-us-east-1}"
export PROJECT="${PROJECT:-cloud-idp}"
export ENV="${ENV:-dev}"

: "${TF_STATE_BUCKET:?set TF_STATE_BUCKET}"
: "${TF_LOCK_TABLE:?set TF_LOCK_TABLE}"

bash scripts/90_destroy_services.sh
bash scripts/91_destroy_platform_addons.sh
bash scripts/92_destroy_platform_core.sh

echo ""
echo "Platform destroyed. If you want to remove backend too, run:"
echo "  bash scripts/99_destroy_bootstrap.sh"
