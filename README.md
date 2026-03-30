# GitOps Templates

> Reusable Helm charts and Kustomize bases for Kubernetes deployments across all Atlas galaxies.

## What this is

A shared library of deployment templates that any galaxy can reference to deploy its workloads on Kubernetes. Instead of each project maintaining its own Deployment/Service/Ingress YAML, galaxies point to this repo and supply only their specific values (image, replicas, resource limits, etc.).

## Repository structure

```
charts/
  app-base/              # Base Helm chart for standard workloads
    Chart.yaml
    values.yaml          # Default values
    values.schema.json   # JSON Schema for value validation
    templates/
      deployment.yaml
      service.yaml
      ingress.yaml
      hpa.yaml
      configmap.yaml
      serviceaccount.yaml
      _helpers.tpl
examples/
  service-values.yaml    # Example consumer values file
.github/
  workflows/
    lint.yml             # Runs helm lint on every PR
```

## How other galaxies use this chart

### Option 1: Helm dependency (recommended)

In your galaxy's `Chart.yaml`:

```yaml
dependencies:
  - name: app-base
    version: "0.1.0"
    repository: "https://raw.githubusercontent.com/<owner>/gitops-templates/main/charts/"
```

Then create a `values.yaml` that overrides the base:

```yaml
app-base:
  name: my-service
  image:
    repository: ghcr.io/<owner>/my-service
    tag: "1.0.0"
  replicas: 3
  service:
    port: 8080
  ingress:
    enabled: true
    host: my-service.example.com
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 256Mi
```

### Option 2: Helm template with remote values

```bash
helm template my-release ./charts/app-base -f my-values.yaml
```

### Option 3: Kustomize overlay (if using kustomize bases)

```yaml
# kustomization.yaml
resources:
  - https://github.com/<owner>/gitops-templates//kustomize/base?ref=main
patchesStrategicMerge:
  - patches/deployment.yaml
```

## Getting started

```bash
# Lint the base chart
helm lint charts/app-base/

# Render templates with example values
helm template test-release charts/app-base/ -f examples/service-values.yaml

# Validate rendered output
helm template test-release charts/app-base/ -f examples/service-values.yaml | kubeval
```

## Agent team

- **gitops-engineer** -- primary agent, writes and maintains Helm charts and Kustomize bases
- **qa-reviewer** -- validates templates with helm lint, kubeval, and schema checks

## Atlas constellation

This galaxy is managed by the Atlas orchestrator workspace at `universe/`.
