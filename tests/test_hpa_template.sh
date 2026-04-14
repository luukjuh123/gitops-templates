#!/usr/bin/env bash
# Test script for app-base HPA template
# Validates that the HorizontalPodAutoscaler template renders correctly

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
echo "=== HPA template tests ==="
echo ""

# --- Test 1: HPA disabled by default — no output ---
echo "-- Test 1: HPA disabled by default — no HPA manifest rendered"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --show-only templates/hpa.yaml 2>&1 || true)

assert_not_contains "no HPA when disabled" "$OUTPUT" "kind: HorizontalPodAutoscaler"

echo ""

# --- Test 2: HPA enabled renders correctly with defaults ---
echo "-- Test 2: HPA enabled renders with default values"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set hpa.enabled=true \
  --show-only templates/hpa.yaml)

assert_contains "kind is HPA"           "$OUTPUT" "kind: HorizontalPodAutoscaler"
assert_contains "apiVersion v2"         "$OUTPUT" "apiVersion: autoscaling/v2"
assert_contains "scaleTargetRef kind"   "$OUTPUT" "kind: Deployment"
assert_contains "scaleTargetRef name"   "$OUTPUT" "name: myapp"
assert_contains "minReplicas 1"         "$OUTPUT" "minReplicas: 1"
assert_contains "maxReplicas 10"        "$OUTPUT" "maxReplicas: 10"
assert_contains "cpu metric"            "$OUTPUT" "name: cpu"
assert_contains "cpu target 80"         "$OUTPUT" "averageUtilization: 80"
assert_not_contains "no memory metric by default" "$OUTPUT" "name: memory"

echo ""

# --- Test 3: Custom min/max replicas ---
echo "-- Test 3: Custom min/max replicas"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set hpa.enabled=true \
  --set hpa.minReplicas=3 \
  --set hpa.maxReplicas=20 \
  --show-only templates/hpa.yaml)

assert_contains "minReplicas 3"  "$OUTPUT" "minReplicas: 3"
assert_contains "maxReplicas 20" "$OUTPUT" "maxReplicas: 20"

echo ""

# --- Test 4: Custom CPU target ---
echo "-- Test 4: Custom CPU utilization target"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set hpa.enabled=true \
  --set hpa.targetCPUUtilizationPercentage=60 \
  --show-only templates/hpa.yaml)

assert_contains "cpu target 60" "$OUTPUT" "averageUtilization: 60"

echo ""

# --- Test 5: Memory metric included when set ---
echo "-- Test 5: Memory utilization metric renders when set"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set hpa.enabled=true \
  --set hpa.targetMemoryUtilizationPercentage=75 \
  --show-only templates/hpa.yaml)

assert_contains "memory metric present" "$OUTPUT" "name: memory"
assert_contains "memory target 75"      "$OUTPUT" "averageUtilization: 75"

echo ""

# --- Test 6: Labels are present ---
echo "-- Test 6: Standard labels are rendered"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set hpa.enabled=true \
  --show-only templates/hpa.yaml)

assert_contains "app name label"    "$OUTPUT" "app.kubernetes.io/name: myapp"
assert_contains "instance label"    "$OUTPUT" "app.kubernetes.io/instance: test-release"
assert_contains "managed-by label"  "$OUTPUT" "app.kubernetes.io/managed-by: Helm"

echo ""

# --- Test 7: helm lint passes with HPA enabled ---
echo "-- Test 7: helm lint with HPA enabled"
if ${HELM} lint "$CHART_DIR" --set hpa.enabled=true --quiet; then
  pass "helm lint passes with HPA enabled"
else
  fail "helm lint failed with HPA enabled"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
