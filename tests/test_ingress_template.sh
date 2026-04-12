#!/usr/bin/env bash
# Test script for app-base Ingress template
# Validates that the Ingress template renders correctly for all supported configurations

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
echo "=== Ingress template tests ==="
echo ""

# --- Test 1: Ingress disabled produces no output ---
echo "-- Test 1: Ingress disabled — no Ingress manifest rendered"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set ingress.enabled=false \
  --show-only templates/ingress.yaml 2>&1 || true)

assert_not_contains "no Ingress when disabled" "$OUTPUT" "kind: Ingress"

echo ""

# --- Test 2: Ingress enabled renders basic manifest ---
echo "-- Test 2: Ingress enabled — host, path, pathType, backend service and port are correct"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set ingress.enabled=true \
  --set ingress.host=myapp.example.com \
  --set ingress.path=/ \
  --set ingress.pathType=Prefix \
  --set service.port=80 \
  --show-only templates/ingress.yaml)

assert_contains "kind is Ingress"              "$OUTPUT" "kind: Ingress"
assert_contains "host is set"                  "$OUTPUT" "host: \"myapp.example.com\""
assert_contains "path is set"                  "$OUTPUT" "path: /"
assert_contains "pathType is Prefix"           "$OUTPUT" "pathType: Prefix"
assert_contains "backend service name"         "$OUTPUT" "name: myapp"
assert_contains "backend service port 80"      "$OUTPUT" "number: 80"

echo ""

# --- Test 3: ingressClassName is set when provided ---
echo "-- Test 3: ingressClassName is rendered when provided"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set ingress.enabled=true \
  --set ingress.host=myapp.example.com \
  --set ingress.className=nginx \
  --show-only templates/ingress.yaml)

assert_contains "ingressClassName is nginx" "$OUTPUT" "ingressClassName: nginx"

echo ""

# --- Test 4: ingressClassName absent when not provided ---
echo "-- Test 4: ingressClassName absent when not provided"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set ingress.enabled=true \
  --set ingress.host=myapp.example.com \
  --show-only templates/ingress.yaml)

assert_not_contains "ingressClassName absent when empty" "$OUTPUT" "ingressClassName:"

echo ""

# --- Test 5: Annotations are rendered when provided ---
echo "-- Test 5: Annotations are rendered when provided"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set ingress.enabled=true \
  --set ingress.host=myapp.example.com \
  --set ingress.annotations."nginx\.ingress\.kubernetes\.io/rewrite-target"=/ \
  --show-only templates/ingress.yaml)

assert_contains "annotation key present" "$OUTPUT" "nginx.ingress.kubernetes.io/rewrite-target"

echo ""

# --- Test 6: TLS section is rendered with secretName and hosts ---
echo "-- Test 6: TLS section renders with secretName and hosts"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set ingress.enabled=true \
  --set ingress.host=myapp.example.com \
  --set "ingress.tls[0].secretName=myapp-tls" \
  --set "ingress.tls[0].hosts[0]=myapp.example.com" \
  --show-only templates/ingress.yaml)

assert_contains "TLS section present"      "$OUTPUT" "tls:"
assert_contains "TLS secretName"           "$OUTPUT" "secretName: myapp-tls"
assert_contains "TLS host"                 "$OUTPUT" "myapp.example.com"

echo ""

# --- Test 7: TLS absent when not configured ---
echo "-- Test 7: TLS absent when not configured"
OUTPUT=$(${HELM} template test-release "$CHART_DIR" \
  --set name=myapp \
  --set ingress.enabled=true \
  --set ingress.host=myapp.example.com \
  --show-only templates/ingress.yaml)

assert_not_contains "no TLS section when not configured" "$OUTPUT" "secretName:"

echo ""

# --- Test 8: helm lint passes ---
echo "-- Test 8: helm lint"
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
