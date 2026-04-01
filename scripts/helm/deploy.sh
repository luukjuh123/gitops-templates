#!/usr/bin/env bash
set -euo pipefail
# Deploy a Helm chart to Kubernetes
RELEASE_NAME="${1:?Usage: deploy.sh <release-name> <chart> <namespace> [values-file]}"
CHART="${2:?}"
NAMESPACE="${3:?}"
VALUES_FILE="${4:-}"
HELM_ARGS=(upgrade --install "$RELEASE_NAME" "$CHART" --namespace "$NAMESPACE" --create-namespace --wait --timeout 5m)
if [[ -n "$VALUES_FILE" ]]; then
  HELM_ARGS+=(-f "$VALUES_FILE")
fi
helm "${HELM_ARGS[@]}"
echo "Deployed $RELEASE_NAME from $CHART to namespace $NAMESPACE"
