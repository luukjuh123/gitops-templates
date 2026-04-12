#!/usr/bin/env bash
set -euo pipefail
# Package all Helm charts into tgz files
CHARTS_DIR="${1:-charts}"
OUTPUT_DIR="${2:-.cr-release-packages}"
mkdir -p "$OUTPUT_DIR"
for chart in "$CHARTS_DIR"/*/; do
  echo "==> Packaging $chart"
  helm package "$chart" -d "$OUTPUT_DIR"
done
echo "Charts packaged to $OUTPUT_DIR"
