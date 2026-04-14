#!/usr/bin/env bash
# Test script for app-base Deployment template
# Validates that the Deployment template renders correctly with various configurations

set -euo pipefail

CHART_DIR="$(cd "$(dirname "$0")/.." && pwd)/charts/app-base"
HELM="${HELM:-helm}"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

assert_contains() {
  local label="$1"
  local haystack="$2"
  local needle="$3"
  if echo "$haystack" | grep -q "$needle"; then
    pass "$label"
  else
    fail "$label — expected to find: $needle"
  fi
}

assert_not_contains() {
  local label="$1"
  local haystack="$2"
  local needle="$3"
  if echo "$haystack" | grep -q "$needle"; then
    fail "$label — expected NOT to find: $needle"
  else
    pass "$label"
  fi
}

echo ""
echo "=== Deployment template tests ==="
echo ""

# --- Test 1: Default deployment renders correctly ---
echo "-- Test 1: Default deployment renders correctly"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --show-only templates/deployment.yaml)

assert_contains "kind is Deployment"         "$OUTPUT" "kind: Deployment"
assert_contains "apiVersion apps/v1"         "$OUTPUT" "apiVersion: apps/v1"
assert_contains "replicas default 1"         "$OUTPUT" "replicas: 1"
assert_contains "container name"             "$OUTPUT" "name: myapp"
assert_contains "default image"              "$OUTPUT" "image: \"nginx:latest\""
assert_contains "pullPolicy IfNotPresent"    "$OUTPUT" "imagePullPolicy: IfNotPresent"
assert_contains "containerPort 80"           "$OUTPUT" "containerPort: 80"
assert_contains "selector label name"        "$OUTPUT" "app.kubernetes.io/name: myapp"
assert_contains "selector label instance"    "$OUTPUT" "app.kubernetes.io/instance: test-release"
assert_contains "resource requests cpu"      "$OUTPUT" "cpu: 100m"
assert_contains "resource requests memory"   "$OUTPUT" "memory: 128Mi"
assert_contains "resource limits cpu"        "$OUTPUT" "cpu: 500m"
assert_contains "resource limits memory"     "$OUTPUT" "memory: 256Mi"

echo ""

# --- Test 2: Custom image and replicas ---
echo "-- Test 2: Custom image and replicas"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapi \
  --set replicas=3 \
  --set image.repository=myregistry/myapi \
  --set image.tag=v1.2.3 \
  --set image.pullPolicy=Always \
  --show-only templates/deployment.yaml)

assert_contains "replicas 3"              "$OUTPUT" "replicas: 3"
assert_contains "custom image"            "$OUTPUT" "image: \"myregistry/myapi:v1.2.3\""
assert_contains "pullPolicy Always"       "$OUTPUT" "imagePullPolicy: Always"

echo ""

# --- Test 3: HPA enabled — replicas field omitted ---
echo "-- Test 3: HPA enabled — replicas field omitted"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set replicas=3 \
  --set hpa.enabled=true \
  --show-only templates/deployment.yaml)

assert_not_contains "no replicas when HPA enabled" "$OUTPUT" "replicas:"

echo ""

# --- Test 4: Environment variables ---
echo "-- Test 4: Environment variables"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set 'env[0].name=DATABASE_URL' \
  --set 'env[0].value=postgres://localhost/db' \
  --show-only templates/deployment.yaml)

assert_contains "env section present"     "$OUTPUT" "env:"
assert_contains "env var name"            "$OUTPUT" "name: DATABASE_URL"
assert_contains "env var value"           "$OUTPUT" "value: postgres://localhost/db"

echo ""

# --- Test 5: Liveness and readiness probes ---
echo "-- Test 5: Liveness and readiness probes"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set 'livenessProbe.httpGet.path=/health' \
  --set 'livenessProbe.httpGet.port=http' \
  --set 'livenessProbe.initialDelaySeconds=10' \
  --set 'readinessProbe.httpGet.path=/ready' \
  --set 'readinessProbe.httpGet.port=http' \
  --set 'readinessProbe.initialDelaySeconds=5' \
  --show-only templates/deployment.yaml)

assert_contains "livenessProbe present"   "$OUTPUT" "livenessProbe:"
assert_contains "liveness path"           "$OUTPUT" "path: /health"
assert_contains "readinessProbe present"  "$OUTPUT" "readinessProbe:"
assert_contains "readiness path"          "$OUTPUT" "path: /ready"

echo ""

# --- Test 6: Pod annotations and labels ---
echo "-- Test 6: Pod annotations and labels"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set-string 'podAnnotations.prometheus\.io/scrape=true' \
  --set 'podLabels.team=backend' \
  --show-only templates/deployment.yaml)

assert_contains "pod annotation"          "$OUTPUT" "prometheus.io/scrape"
assert_contains "pod label"               "$OUTPUT" "team: backend"

echo ""

# --- Test 7: Image pull secrets ---
echo "-- Test 7: Image pull secrets"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set 'imagePullSecrets[0]=my-registry-secret' \
  --show-only templates/deployment.yaml)

assert_contains "imagePullSecrets"        "$OUTPUT" "imagePullSecrets:"
assert_contains "secret name"             "$OUTPUT" "name: my-registry-secret"

echo ""

# --- Test 8: ServiceAccount reference ---
echo "-- Test 8: ServiceAccount reference"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set serviceAccount.create=true \
  --set serviceAccount.name=custom-sa \
  --show-only templates/deployment.yaml)

assert_contains "serviceAccountName"      "$OUTPUT" "serviceAccountName: custom-sa"

echo ""

# --- Test 9: ServiceAccount not created — no serviceAccountName ---
echo "-- Test 9: ServiceAccount disabled — no serviceAccountName"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set serviceAccount.create=false \
  --show-only templates/deployment.yaml)

assert_not_contains "no serviceAccountName when disabled" "$OUTPUT" "serviceAccountName:"

echo ""

# --- Test 10: Node selector, tolerations, affinity ---
echo "-- Test 10: Node selector, tolerations, affinity"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set 'nodeSelector.disktype=ssd' \
  --set 'tolerations[0].key=dedicated' \
  --set 'tolerations[0].operator=Equal' \
  --set 'tolerations[0].value=gpu' \
  --set 'tolerations[0].effect=NoSchedule' \
  --show-only templates/deployment.yaml)

assert_contains "nodeSelector"            "$OUTPUT" "nodeSelector:"
assert_contains "disktype ssd"            "$OUTPUT" "disktype: ssd"
assert_contains "tolerations"             "$OUTPUT" "tolerations:"
assert_contains "toleration key"          "$OUTPUT" "key: dedicated"

echo ""

# --- Test 11: Volumes and volume mounts ---
echo "-- Test 11: Volumes and volume mounts"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set 'volumeMounts[0].name=data' \
  --set 'volumeMounts[0].mountPath=/data' \
  --set 'volumes[0].name=data' \
  --set 'volumes[0].emptyDir.medium=Memory' \
  --show-only templates/deployment.yaml)

assert_contains "volumeMounts"            "$OUTPUT" "volumeMounts:"
assert_contains "mountPath"               "$OUTPUT" "mountPath: /data"
assert_contains "volumes"                 "$OUTPUT" "volumes:"
assert_contains "volume name"             "$OUTPUT" "name: data"

echo ""

# --- Test 12: Standard labels present ---
echo "-- Test 12: Standard labels present"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --show-only templates/deployment.yaml)

assert_contains "helm chart label"        "$OUTPUT" "helm.sh/chart:"
assert_contains "managed-by label"        "$OUTPUT" "app.kubernetes.io/managed-by: Helm"
assert_contains "version label"           "$OUTPUT" "app.kubernetes.io/version:"

echo ""

# --- Test 13: helm lint passes ---
echo "-- Test 13: helm lint"
if ${HELM} lint "$CHART_DIR" --quiet; then
  pass "helm lint passes"
else
  fail "helm lint failed"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
