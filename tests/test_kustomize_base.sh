#!/usr/bin/env bash
# Test suite for kustomize/base and kustomize/components
# Validates YAML syntax, required Kubernetes fields, and kustomization structure.
# Uses python3 (yaml module) so no kustomize binary is required to run these tests.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE_DIR="$REPO_ROOT/kustomize/base"
COMPONENTS_DIR="$REPO_ROOT/kustomize/components"
OVERLAYS_DIR="$REPO_ROOT/kustomize/overlays"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

assert_file_exists() {
  local label="$1"
  local path="$2"
  if [ -f "$path" ]; then
    pass "$label"
  else
    fail "$label — file not found: $path"
  fi
}

assert_yaml_valid() {
  local label="$1"
  local path="$2"
  if python3 -c "import yaml, sys; list(yaml.safe_load_all(open('$path')))" 2>/dev/null; then
    pass "$label"
  else
    fail "$label — invalid YAML: $path"
  fi
}

assert_yaml_field() {
  local label="$1"
  local path="$2"
  local field="$3"
  local expected="$4"
  local actual
  actual=$(python3 -c "
import yaml, sys
doc = yaml.safe_load(open('$path'))
keys = '$field'.split('.')
val = doc
for k in keys:
    val = val.get(k, '') if isinstance(val, dict) else ''
print(val)
" 2>/dev/null)
  if [ "$actual" = "$expected" ]; then
    pass "$label"
  else
    fail "$label — expected '$expected', got '$actual' (field: $field)"
  fi
}

assert_yaml_contains_item() {
  local label="$1"
  local path="$2"
  local key="$3"    # dotted key path to a list
  local item="$4"   # item that should be in the list
  local result
  result=$(python3 -c "
import yaml, sys
doc = yaml.safe_load(open('$path'))
keys = '$key'.split('.')
val = doc
for k in keys:
    val = val.get(k, []) if isinstance(val, dict) else []
print('yes' if '$item' in (val or []) else 'no')
" 2>/dev/null)
  if [ "$result" = "yes" ]; then
    pass "$label"
  else
    fail "$label — '$item' not found in $key"
  fi
}

echo ""
echo "=== Kustomize base — file existence ==="
echo ""

assert_file_exists "base/kustomization.yaml exists"    "$BASE_DIR/kustomization.yaml"
assert_file_exists "base/deployment.yaml exists"       "$BASE_DIR/deployment.yaml"
assert_file_exists "base/service.yaml exists"          "$BASE_DIR/service.yaml"
assert_file_exists "base/serviceaccount.yaml exists"   "$BASE_DIR/serviceaccount.yaml"

echo ""
echo "=== Kustomize components — file existence ==="
echo ""

assert_file_exists "components/ingress/kustomization.yaml exists"  "$COMPONENTS_DIR/ingress/kustomization.yaml"
assert_file_exists "components/ingress/ingress.yaml exists"        "$COMPONENTS_DIR/ingress/ingress.yaml"
assert_file_exists "components/hpa/kustomization.yaml exists"      "$COMPONENTS_DIR/hpa/kustomization.yaml"
assert_file_exists "components/hpa/hpa.yaml exists"                "$COMPONENTS_DIR/hpa/hpa.yaml"
assert_file_exists "components/configmap/kustomization.yaml exists" "$COMPONENTS_DIR/configmap/kustomization.yaml"
assert_file_exists "components/configmap/configmap.yaml exists"    "$COMPONENTS_DIR/configmap/configmap.yaml"

echo ""
echo "=== YAML syntax validation ==="
echo ""

for f in \
  "$BASE_DIR/kustomization.yaml" \
  "$BASE_DIR/deployment.yaml" \
  "$BASE_DIR/service.yaml" \
  "$BASE_DIR/serviceaccount.yaml" \
  "$COMPONENTS_DIR/ingress/kustomization.yaml" \
  "$COMPONENTS_DIR/ingress/ingress.yaml" \
  "$COMPONENTS_DIR/hpa/kustomization.yaml" \
  "$COMPONENTS_DIR/hpa/hpa.yaml" \
  "$COMPONENTS_DIR/configmap/kustomization.yaml" \
  "$COMPONENTS_DIR/configmap/configmap.yaml" \
  "$OVERLAYS_DIR/example/kustomization.yaml" \
  "$OVERLAYS_DIR/example/deployment-patch.yaml" \
  "$OVERLAYS_DIR/example/ingress-patch.yaml"; do
  name="$(basename "$(dirname "$f")")/$(basename "$f")"
  assert_yaml_valid "YAML valid: $name" "$f"
done

echo ""
echo "=== base/kustomization.yaml structure ==="
echo ""

assert_yaml_field "base kustomization apiVersion" \
  "$BASE_DIR/kustomization.yaml" "apiVersion" "kustomize.config.k8s.io/v1beta1"
assert_yaml_field "base kustomization kind" \
  "$BASE_DIR/kustomization.yaml" "kind" "Kustomization"
assert_yaml_contains_item "base resources includes deployment.yaml" \
  "$BASE_DIR/kustomization.yaml" "resources" "deployment.yaml"
assert_yaml_contains_item "base resources includes service.yaml" \
  "$BASE_DIR/kustomization.yaml" "resources" "service.yaml"
assert_yaml_contains_item "base resources includes serviceaccount.yaml" \
  "$BASE_DIR/kustomization.yaml" "resources" "serviceaccount.yaml"

echo ""
echo "=== base/deployment.yaml structure ==="
echo ""

assert_yaml_field "deployment apiVersion"       "$BASE_DIR/deployment.yaml" "apiVersion" "apps/v1"
assert_yaml_field "deployment kind"             "$BASE_DIR/deployment.yaml" "kind" "Deployment"
assert_yaml_field "deployment metadata.name"    "$BASE_DIR/deployment.yaml" "metadata.name" "app"

echo ""
echo "=== base/service.yaml structure ==="
echo ""

assert_yaml_field "service apiVersion"       "$BASE_DIR/service.yaml" "apiVersion" "v1"
assert_yaml_field "service kind"             "$BASE_DIR/service.yaml" "kind" "Service"
assert_yaml_field "service metadata.name"    "$BASE_DIR/service.yaml" "metadata.name" "app"
assert_yaml_field "service spec.type"        "$BASE_DIR/service.yaml" "spec.type" "ClusterIP"

echo ""
echo "=== base/serviceaccount.yaml structure ==="
echo ""

assert_yaml_field "serviceaccount apiVersion"    "$BASE_DIR/serviceaccount.yaml" "apiVersion" "v1"
assert_yaml_field "serviceaccount kind"          "$BASE_DIR/serviceaccount.yaml" "kind" "ServiceAccount"
assert_yaml_field "serviceaccount metadata.name" "$BASE_DIR/serviceaccount.yaml" "metadata.name" "app"

echo ""
echo "=== components/ingress — structure ==="
echo ""

assert_yaml_field "ingress component kind" \
  "$COMPONENTS_DIR/ingress/kustomization.yaml" "kind" "Component"
assert_yaml_field "ingress apiVersion" \
  "$COMPONENTS_DIR/ingress/ingress.yaml" "apiVersion" "networking.k8s.io/v1"
assert_yaml_field "ingress kind" \
  "$COMPONENTS_DIR/ingress/ingress.yaml" "kind" "Ingress"

echo ""
echo "=== components/hpa — structure ==="
echo ""

assert_yaml_field "hpa component kind" \
  "$COMPONENTS_DIR/hpa/kustomization.yaml" "kind" "Component"
assert_yaml_field "hpa apiVersion" \
  "$COMPONENTS_DIR/hpa/hpa.yaml" "apiVersion" "autoscaling/v2"
assert_yaml_field "hpa kind" \
  "$COMPONENTS_DIR/hpa/hpa.yaml" "kind" "HorizontalPodAutoscaler"

echo ""
echo "=== components/configmap — structure ==="
echo ""

assert_yaml_field "configmap component kind" \
  "$COMPONENTS_DIR/configmap/kustomization.yaml" "kind" "Component"
assert_yaml_field "configmap apiVersion" \
  "$COMPONENTS_DIR/configmap/configmap.yaml" "apiVersion" "v1"
assert_yaml_field "configmap kind" \
  "$COMPONENTS_DIR/configmap/configmap.yaml" "kind" "ConfigMap"

echo ""
echo "=== overlays/example — structure ==="
echo ""

assert_yaml_field "example overlay apiVersion" \
  "$OVERLAYS_DIR/example/kustomization.yaml" "apiVersion" "kustomize.config.k8s.io/v1beta1"
assert_yaml_field "example overlay kind" \
  "$OVERLAYS_DIR/example/kustomization.yaml" "kind" "Kustomization"
assert_yaml_contains_item "example overlay resources includes ../../base" \
  "$OVERLAYS_DIR/example/kustomization.yaml" "resources" "../../base"

echo ""
echo "=== kustomize build smoke test (skipped if kustomize not installed) ==="
echo ""

if command -v kustomize &>/dev/null; then
  if kustomize build "$BASE_DIR" >/dev/null 2>&1; then
    pass "kustomize build base succeeds"
  else
    fail "kustomize build base failed"
  fi
  if kustomize build "$OVERLAYS_DIR/example" >/dev/null 2>&1; then
    pass "kustomize build overlays/example succeeds"
  else
    fail "kustomize build overlays/example failed"
  fi
else
  echo "  SKIP: kustomize binary not found — install kustomize to enable build tests"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
echo ""

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
