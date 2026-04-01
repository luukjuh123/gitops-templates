#!/usr/bin/env bash
set -euo pipefail
DIR="${1:-.}"
echo "==> terraform fmt check in $DIR"
terraform fmt -check -recursive "$DIR"
echo "All Terraform files are correctly formatted."
