# GitOps Templates

Reusable Helm charts and Kustomize bases for deploying applications on Kubernetes. Other galaxies reference these templates via a YAML configuration file to specify variables (image tag, replicas, resource limits) without duplicating deployment code.

## Stack
- Kubernetes YAML
- Helm 3 (charts with values)
- Kustomize (optional bases)
- GitHub Actions (helm lint, kubeval)

## Agent Team
| Agent | Role |
|-------|------|
| gitops-engineer | Primary — writes and maintains Helm charts and Kustomize bases |
| qa-reviewer | Validates templates with helm lint, kubeval, and schema checks |

## Conventions
- Test-first: validate charts with helm lint and kubeval before merging
- PRs only: never push to main — every todo item gets its own PR
- All charts must include a `values.schema.json` for input validation
- Consumer galaxies reference charts via Git URL, never copy templates

## Imports
@.claude/rules/test-first.md
@.claude/rules/pr-workflow.md
