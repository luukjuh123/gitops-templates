#!/usr/bin/env bash
set -euo pipefail
MANIFEST_DIR="${1:?Usage: kubeconform.sh <manifest-dir> [kubernetes-version]}"
K8S_VERSION="${2:-1.29.0}"
echo "==> Validating Kubernetes manifests in $MANIFEST_DIR (k8s $K8S_VERSION)"
find "$MANIFEST_DIR" -name "*.yaml" -o -name "*.yml" | \
  xargs kubeconform -strict -kubernetes-version "$K8S_VERSION" -summary
