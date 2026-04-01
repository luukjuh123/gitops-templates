#!/usr/bin/env bash
# Test script for app-base Service template
# Validates that the Service template renders correctly for all supported types

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
echo "=== Service template tests ==="
echo ""

# --- Test 1: Service is rendered by default (ClusterIP) ---
echo "-- Test 1: Default ClusterIP service renders correctly"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set service.enabled=true \
  --set service.type=ClusterIP \
  --set service.port=80 \
  --set service.targetPort=8080 \
  --show-only templates/service.yaml)

assert_contains "kind is Service"       "$OUTPUT" "kind: Service"
assert_contains "ClusterIP type"        "$OUTPUT" "type: ClusterIP"
assert_contains "port 80"               "$OUTPUT" "port: 80"
assert_contains "targetPort 8080"       "$OUTPUT" "targetPort: 8080"
assert_contains "app.kubernetes.io/name label" "$OUTPUT" "app.kubernetes.io/name: myapp"
assert_not_contains "nodePort field absent for ClusterIP" "$OUTPUT" "nodePort:"

echo ""

# --- Test 2: NodePort service includes nodePort field ---
echo "-- Test 2: NodePort service renders correctly"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set service.enabled=true \
  --set service.type=NodePort \
  --set service.port=80 \
  --set service.targetPort=8080 \
  --set service.nodePort=30080 \
  --show-only templates/service.yaml)

assert_contains "kind is Service"   "$OUTPUT" "kind: Service"
assert_contains "NodePort type"     "$OUTPUT" "type: NodePort"
assert_contains "nodePort: 30080"   "$OUTPUT" "nodePort: 30080"

echo ""

# --- Test 3: LoadBalancer service type ---
echo "-- Test 3: LoadBalancer service renders correctly"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set service.enabled=true \
  --set service.type=LoadBalancer \
  --set service.port=443 \
  --set service.targetPort=8443 \
  --show-only templates/service.yaml)

assert_contains "kind is Service"      "$OUTPUT" "kind: Service"
assert_contains "LoadBalancer type"    "$OUTPUT" "type: LoadBalancer"
assert_contains "port 443"             "$OUTPUT" "port: 443"
assert_contains "targetPort 8443"      "$OUTPUT" "targetPort: 8443"

echo ""

# --- Test 4: Service disabled produces no output ---
echo "-- Test 4: Service disabled — no Service manifest rendered"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set service.enabled=false \
  --show-only templates/service.yaml 2>&1 || true)

assert_not_contains "no Service when disabled" "$OUTPUT" "kind: Service"

echo ""

# --- Test 5: Service annotations are applied ---
echo "-- Test 5: Service annotations are rendered"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set service.enabled=true \
  --set service.annotations."cloud\.example\.com/lb-type"=internal \
  --show-only templates/service.yaml)

assert_contains "annotation key present" "$OUTPUT" "cloud.example.com/lb-type"

echo ""

# --- Test 6: helm lint passes ---
echo "-- Test 6: helm lint"
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
