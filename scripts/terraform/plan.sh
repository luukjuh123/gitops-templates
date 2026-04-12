#!/usr/bin/env bash
set -euo pipefail
DIR="${1:-.}"
PLAN_FILE="${2:-tfplan}"
echo "==> terraform plan"
terraform -chdir="$DIR" plan -out="$PLAN_FILE" -input=false
echo "Plan saved to $PLAN_FILE"
