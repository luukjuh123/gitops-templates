#!/usr/bin/env bash
# Test script for docker-build.yml reusable workflow
# Validates structure, required fields, and expected behaviour of the workflow YAML.

set -euo pipefail

WORKFLOW_FILE="$(cd "$(dirname "$0")/.." && pwd)/.github/workflows/docker-build.yml"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

assert_contains() {
  local label="$1" file="$2" needle="$3"
  if grep -q "$needle" "$file"; then
    pass "$label"
  else
    fail "$label — expected to find: $needle"
  fi
}

assert_not_contains() {
  local label="$1" file="$2" needle="$3"
  if grep -q "$needle" "$file"; then
    fail "$label — expected NOT to find: $needle"
  else
    pass "$label"
  fi
}

echo ""
echo "=== docker-build.yml workflow tests ==="
echo ""

# ---- Test 1: file exists ----
echo "-- Test 1: workflow file exists"
if [ -f "$WORKFLOW_FILE" ]; then
  pass "docker-build.yml exists"
else
  fail "docker-build.yml not found at $WORKFLOW_FILE"
fi

# ---- Test 2: reusable trigger ----
echo ""
echo "-- Test 2: workflow_call trigger present"
assert_contains "workflow_call trigger" "$WORKFLOW_FILE" "workflow_call:"

# ---- Test 3: required inputs ----
echo ""
echo "-- Test 3: required inputs declared"
assert_contains "image-name input"  "$WORKFLOW_FILE" "image-name:"
assert_contains "registry input"    "$WORKFLOW_FILE" "registry:"
assert_contains "push input"        "$WORKFLOW_FILE" "push:"

# ---- Test 4: optional inputs for flexibility ----
echo ""
echo "-- Test 4: optional inputs for dockerfile and build-args"
assert_contains "dockerfile input"  "$WORKFLOW_FILE" "dockerfile:"
assert_contains "build-args input"  "$WORKFLOW_FILE" "build-args:"

# ---- Test 5: secrets for registry auth ----
echo ""
echo "-- Test 5: secrets for registry authentication"
assert_contains "REGISTRY_USERNAME secret" "$WORKFLOW_FILE" "REGISTRY_USERNAME:"
assert_contains "REGISTRY_PASSWORD secret" "$WORKFLOW_FILE" "REGISTRY_PASSWORD:"

# ---- Test 6: Docker Buildx setup ----
echo ""
echo "-- Test 6: Docker Buildx action used"
assert_contains "setup-buildx-action" "$WORKFLOW_FILE" "setup-buildx-action"

# ---- Test 7: login conditional on push ----
echo ""
echo "-- Test 7: login step is conditional on push input"
assert_contains "login conditional" "$WORKFLOW_FILE" "inputs.push"

# ---- Test 8: docker/build-push-action used ----
echo ""
echo "-- Test 8: docker/build-push-action used for build"
assert_contains "build-push-action" "$WORKFLOW_FILE" "build-push-action"

# ---- Test 9: GHA cache configured ----
echo ""
echo "-- Test 9: GitHub Actions cache configured"
assert_contains "cache-from gha" "$WORKFLOW_FILE" "cache-from"
assert_contains "cache-to gha"   "$WORKFLOW_FILE" "cache-to"

# ---- Test 10: metadata action for labels ----
echo ""
echo "-- Test 10: docker/metadata-action used for image labels"
assert_contains "metadata-action" "$WORKFLOW_FILE" "metadata-action"

# ---- Test 11: packages write permission for GHCR ----
echo ""
echo "-- Test 11: packages: write permission present (GHCR support)"
assert_contains "packages write" "$WORKFLOW_FILE" "packages: write"

# ---- Test 12: YAML is valid (requires yq or python) ----
echo ""
echo "-- Test 12: YAML syntax is valid"
if command -v python3 &>/dev/null; then
  if python3 -c "import yaml; yaml.safe_load(open('$WORKFLOW_FILE'))" 2>/dev/null; then
    pass "YAML parses without error"
  else
    fail "YAML syntax error in $WORKFLOW_FILE"
  fi
else
  pass "YAML syntax check skipped (python3 not available)"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
