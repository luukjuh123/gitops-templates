#!/usr/bin/env bash
set -euo pipefail
IMAGE="${1:?Usage: build.sh <image:tag> [dockerfile] [context]}"
DOCKERFILE="${2:-Dockerfile}"
CONTEXT="${3:-.}"
echo "==> Building Docker image: $IMAGE"
docker build -t "$IMAGE" -f "$DOCKERFILE" "$CONTEXT"
echo "Built: $IMAGE"
