#!/usr/bin/env bash
# Test script for app-base ServiceAccount template
# Validates that the ServiceAccount template renders correctly

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
echo "=== ServiceAccount template tests ==="
echo ""

# --- Test 1: ServiceAccount is rendered by default ---
echo "-- Test 1: Default ServiceAccount renders correctly"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set serviceAccount.create=true \
  --show-only templates/serviceaccount.yaml)

assert_contains "kind is ServiceAccount"              "$OUTPUT" "kind: ServiceAccount"
assert_contains "apiVersion v1"                       "$OUTPUT" "apiVersion: v1"
assert_contains "name is myapp"                       "$OUTPUT" "name: myapp"
assert_contains "app.kubernetes.io/name label"        "$OUTPUT" "app.kubernetes.io/name: myapp"

echo ""

# --- Test 2: Custom ServiceAccount name is used ---
echo "-- Test 2: Custom ServiceAccount name is used when specified"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set serviceAccount.create=true \
  --set serviceAccount.name=custom-sa \
  --show-only templates/serviceaccount.yaml)

assert_contains "custom name used" "$OUTPUT" "name: custom-sa"

echo ""

# --- Test 3: ServiceAccount disabled produces no output ---
echo "-- Test 3: ServiceAccount disabled — no manifest rendered"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set serviceAccount.create=false \
  --show-only templates/serviceaccount.yaml 2>&1 || true)

assert_not_contains "no ServiceAccount when disabled" "$OUTPUT" "kind: ServiceAccount"

echo ""

# --- Test 4: Annotations are applied ---
echo "-- Test 4: ServiceAccount annotations are rendered"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set serviceAccount.create=true \
  --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=arn:aws:iam::123456789:role/my-role" \
  --show-only templates/serviceaccount.yaml)

assert_contains "annotation key present" "$OUTPUT" "eks.amazonaws.com/role-arn"

echo ""

# --- Test 5: No annotations section rendered when annotations empty ---
echo "-- Test 5: No annotations block when annotations is empty"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set serviceAccount.create=true \
  --show-only templates/serviceaccount.yaml)

assert_not_contains "no annotations block when empty" "$OUTPUT" "annotations:"

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
