#!/usr/bin/env bash
set -euo pipefail
# Lint all Helm charts in the charts/ directory
CHARTS_DIR="${1:-charts}"
for chart in "$CHARTS_DIR"/*/; do
  echo "==> Linting $chart"
  helm lint "$chart"
done
echo "All charts passed helm lint."
