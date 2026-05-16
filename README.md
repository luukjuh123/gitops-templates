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
  service-values.yaml    # Example consumer values file
.github/
  workflows/
    lint.yml             # Runs helm lint + kubeconform + version-check on every PR
    release.yml          # Packages and releases charts to gh-pages on push to main
.cr.yaml                 # chart-releaser configuration
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

First add the Helm repository (published automatically to GitHub Pages on every release):

```bash
helm repo add gitops-templates https://luukjuh123.github.io/gitops-templates
helm repo update
```

In your galaxy's `Chart.yaml`, pin the chart to a specific version:

```yaml
dependencies:
  - name: app-base
    version: "0.1.0"
    repository: "https://luukjuh123.github.io/gitops-templates"
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

## Chart versioning

Charts in this repository follow [Semantic Versioning](https://semver.org/):

| Change type | Version bump | Example |
|---|---|---|
| Bug fix in a template or a default value correction | `patch` | `0.1.0` -> `0.1.1` |
| New optional value or backwards-compatible feature | `minor` | `0.1.0` -> `0.2.0` |
| Renamed/removed required values or structural changes | `major` | `0.1.0` -> `1.0.0` |

The `version` field in `Chart.yaml` must be bumped on every PR that modifies chart files. The
`lint.yml` CI workflow enforces this via the `version-check` job — PRs that change chart source
files without bumping the version will fail CI.

The `appVersion` field in `Chart.yaml` tracks the default application version this chart is
designed for and is independent of the chart version.

### Release process

Releases happen automatically:

1. Merge a PR to `main` that bumps `version` in `Chart.yaml`.
2. The `release.yml` workflow detects the new version, packages the chart as a `.tgz`,
   creates a GitHub Release with the package as an asset, and updates the `index.yaml` on
   the `gh-pages` branch.
3. Consumers running `helm repo update` will see the new version immediately.

## Getting started

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
