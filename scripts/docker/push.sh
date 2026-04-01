#!/usr/bin/env bash
set -euo pipefail
IMAGE="${1:?Usage: push.sh <image:tag>}"
echo "==> Pushing Docker image: $IMAGE"
docker push "$IMAGE"
echo "Pushed: $IMAGE"
