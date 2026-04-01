#!/usr/bin/env bash
set -euo pipefail
RESOURCE="${1:?Usage: rollout-wait.sh <deployment|statefulset/name> <namespace>}"
NAMESPACE="${2:?}"
TIMEOUT="${3:-5m}"
echo "==> Waiting for rollout: $RESOURCE in $NAMESPACE (timeout: $TIMEOUT)"
kubectl rollout status "$RESOURCE" -n "$NAMESPACE" --timeout="$TIMEOUT"
echo "Rollout complete."
