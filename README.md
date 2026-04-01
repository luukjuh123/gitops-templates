# GitOps Templates

> The Atlas DevOps template library — reusable CI/CD workflows, Helm charts, scripts, and tooling configuration for all Atlas galaxies.

## What this is

A shared library of DevOps templates. Galaxies call reusable GitHub Actions workflows directly (updates propagate automatically) and reference Helm charts via Git URL for Kubernetes deployments.

## Repository structure

```
.github/
  workflows/          # Reusable workflows (on: workflow_call) + this repo's CI
  actions/            # Composite actions (setup-python, setup-rust, etc.)
ci/
  python/             # Standalone CI template Genesis copies into Python galaxies
  rust/               # Standalone CI template Genesis copies into Rust galaxies
  typescript/         # Standalone CI template Genesis copies into TS galaxies
charts/
  app-base/           # Base Helm chart for standard workloads
  cronjob/            # Helm chart for CronJob workloads
  statefulset/        # Helm chart for StatefulSet workloads
scripts/
  helm/               # lint-all.sh, package.sh, deploy.sh
  terraform/          # fmt-check.sh, validate.sh, plan.sh
  kubernetes/         # kubeconform.sh, rollout-wait.sh
  docker/             # build.sh, push.sh
examples/
  reusable-workflows/ # Example CI workflows for each stack
  helm/               # Example Helm values files
  terraform/          # Example Terraform CI
```

## GitHub Actions

### Reusable Workflows

Call these from any galaxy's CI workflow:

```yaml
jobs:
  quality:
    uses: luukjuh123/gitops-templates/.github/workflows/python-quality.yml@main
    with:
      python-version: '3.12'
```

| Workflow file | Stack | Inputs |
|---------------|-------|--------|
| `python-quality.yml` | Python | python-version, src-dir |
| `python-test.yml` | Python | python-version, coverage-threshold |
| `rust-quality.yml` | Rust | rust-channel |
| `rust-test.yml` | Rust | rust-channel, all-features |
| `rust-build.yml` | Rust | rust-channel |
| `rust-audit.yml` | Rust | — (also runs on schedule) |
| `typescript-quality.yml` | TypeScript | node-version |
| `typescript-test.yml` | TypeScript | node-version |
| `typescript-build.yml` | TypeScript | node-version |
| `helm-lint.yml` | Helm | charts-dir, kubernetes-version |
| `helm-release.yml` | Helm | charts-dir |
| `terraform-validate.yml` | Terraform | terraform-version, working-directory |
| `docker-build.yml` | Docker | image-name, registry, push |

See `examples/reusable-workflows/` for complete per-stack examples.

### Composite Actions

```yaml
- uses: luukjuh123/gitops-templates/.github/actions/setup-python@main
  with:
    python-version: '3.12'
```

| Action | Purpose |
|--------|---------|
| `setup-python` | Python + uv + `uv sync --all-extras --dev` |
| `setup-rust` | Rust toolchain + Swatinem/rust-cache |
| `setup-node` | Node.js + `npm ci` |
| `setup-helm` | Helm + kubeconform |
| `setup-terraform` | Terraform + tflint |

## Helm Charts

### How other galaxies use this chart

In your galaxy's `Chart.yaml`:

```yaml
dependencies:
  - name: app-base
    version: "0.1.0"
    repository: "https://raw.githubusercontent.com/luukjuh123/gitops-templates/main/charts/"
```

Then create a `values.yaml` that overrides the base:

```yaml
app-base:
  name: my-service
  image:
    repository: ghcr.io/luukjuh123/my-service
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

### Getting started with Helm

```bash
# Lint the base chart
helm lint charts/app-base/

# Render templates with example values
helm template test-release charts/app-base/ -f examples/helm/service-values.yaml

# Validate rendered output
helm template test-release charts/app-base/ -f examples/helm/service-values.yaml | kubeconform -strict -summary
```

## Agent team

- **gitops-engineer** — maintains all templates, adds new workflow/chart variants, keeps templates current

## Atlas constellation

This galaxy is managed by the Atlas orchestrator workspace at `universe/`.
