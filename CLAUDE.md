# gitops-templates

The Atlas DevOps template library. Single source of truth for CI/CD workflows, Helm charts, Kustomize bases, scripts, and tooling configuration across all Atlas galaxies.

## Purpose

All Atlas galaxies reference this repo for:
- **Reusable GitHub Actions workflows** — call via `uses: luukjuh123/gitops-templates/.github/workflows/[name].yml@main`
- **Composite actions** — call via `uses: luukjuh123/gitops-templates/.github/actions/[name]@main`
- **Standalone CI templates** — Genesis copies `ci/{stack}/ci.yml` into new galaxies on bootstrap
- **Helm charts** — galaxies reference via Git URL for Kubernetes deployments
- **Scripts** — reusable shell scripts for helm, terraform, kubernetes, docker

## Structure

| Directory | Contents |
|-----------|----------|
| `.github/workflows/` | Reusable workflows + this repo's own CI |
| `.github/actions/` | Composite actions (setup-python, setup-rust, etc.) |
| `ci/` | Standalone CI templates for Python, Rust, TypeScript |
| `charts/` | Helm charts: app-base, cronjob, statefulset |
| `scripts/` | Shell scripts: helm/, terraform/, kubernetes/, docker/ |
| `examples/` | Usage examples for all templates |

## Reusable Workflows

| Workflow | `uses:` path | Inputs |
|----------|-------------|--------|
| Python quality | `python-quality.yml` | python-version, src-dir |
| Python tests | `python-test.yml` | python-version, coverage-threshold |
| Rust quality | `rust-quality.yml` | rust-channel |
| Rust tests | `rust-test.yml` | rust-channel, all-features |
| Rust build | `rust-build.yml` | rust-channel |
| Rust audit | `rust-audit.yml` | — |
| TypeScript quality | `typescript-quality.yml` | node-version |
| TypeScript tests | `typescript-test.yml` | node-version |
| TypeScript build | `typescript-build.yml` | node-version |
| Helm lint | `helm-lint.yml` | charts-dir, kubernetes-version |
| Helm release | `helm-release.yml` | charts-dir |
| Terraform validate | `terraform-validate.yml` | terraform-version, working-directory |
| Docker build | `docker-build.yml` | image-name, registry, push |

Call pattern: `uses: luukjuh123/gitops-templates/.github/workflows/[workflow]@main`

## Composite Actions

| Action | `uses:` path | Purpose |
|--------|-------------|---------|
| setup-python | `.github/actions/setup-python` | Python + uv + dep install |
| setup-rust | `.github/actions/setup-rust` | Rust toolchain + cache |
| setup-node | `.github/actions/setup-node` | Node.js + npm ci |
| setup-helm | `.github/actions/setup-helm` | Helm + kubeconform |
| setup-terraform | `.github/actions/setup-terraform` | Terraform + tflint |

## Agent

| Agent | Role |
|-------|------|
| gitops-engineer | Maintains all templates, adds new workflow/chart variants, keeps templates current |

## Rules

@../../.claude/rules/test-first.md
@../../.claude/rules/pr-workflow.md
