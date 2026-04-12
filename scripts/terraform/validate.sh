#!/usr/bin/env bash
set -euo pipefail
DIR="${1:-.}"
echo "==> terraform init (no backend)"
terraform -chdir="$DIR" init -backend=false -input=false
echo "==> terraform validate"
terraform -chdir="$DIR" validate
echo "Terraform configuration is valid."
