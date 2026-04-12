# Threat Model — gitops-templates — 2026-04-02

## Trust Boundaries

- **Template consumer tier**: All Atlas galaxies that reference these Helm charts and GitHub Actions workflows via `uses: luukjuh123/gitops-templates/.github/workflows/...@main`. Changes to these templates propagate automatically to all consumers.
- **CI/CD execution tier**: GitHub Actions runners that execute the reusable workflows — trusted to execute the defined steps, but workflow inputs from consumer repos are untrusted.
- **Kubernetes cluster tier**: Clusters that deploy workloads using these Helm charts — the chart templates define the security posture of every deployed app.
- **Helm chart authoring tier**: gitops-engineer agent that modifies chart templates — changes have blast-radius across all galaxies.

## Assets

| Asset | Sensitivity | Location |
|-------|-------------|----------|
| Reusable GitHub Actions workflows | CRITICAL — executed in every galaxy's CI/CD pipeline | `.github/workflows/` |
| Helm chart templates (deployment, ingress, RBAC) | HIGH — define Kubernetes security posture for all apps | `charts/app-base/`, `charts/cronjob/`, `charts/statefulset/` |
| `charts/app-base/values.yaml` defaults | HIGH — insecure defaults propagate to all consumers | `charts/app-base/values.yaml` |
| GitHub Actions secrets passed as workflow inputs | HIGH | GitHub Actions encrypted secrets |

## Threats

| ID | Threat | Likelihood | Impact | Mitigation |
|----|--------|------------|--------|------------|
| T1 | Supply-chain compromise — a malicious commit to `main` in this repo propagates a backdoored workflow or chart to all galaxy CI/CD pipelines (all consumers pin to `@main`) | MEDIUM | CRITICAL | Require PR + code review for all changes to `.github/workflows/` and `charts/`; consider pinning consumers to tagged releases rather than `@main` |
| T2 | Helm chart Deployment template has no `securityContext` — all deployed containers run as root by default, enabling privilege escalation if the container is compromised | HIGH | HIGH | Add `securityContext` with `runAsNonRoot: true`, `readOnlyRootFilesystem: true`, and `allowPrivilegeEscalation: false` to the default Deployment template |
| T3 | `image.tag: "latest"` default in `values.yaml` causes unpredictable image versions to be deployed in consumer galaxies, introducing unverified code | HIGH | MEDIUM | Change the default `image.tag` to a pinned version (e.g., `"stable"` or require override); add a values schema validation that rejects `"latest"` in production |
| T4 | Ingress template has no TLS configuration by default — deployed services may be exposed over plain HTTP in cluster environments that don't auto-provision TLS | MEDIUM | HIGH | Set the Ingress template to require explicit TLS configuration; add a linting rule that warns when TLS is not configured |
| T5 | GitHub Actions workflow inputs from consumer repos are untrusted — a consumer could pass a malicious `src-dir` or `working-directory` input containing shell metacharacters that get interpolated unsafely | LOW | HIGH | Use `${{ inputs.parameter }}` in `with:` blocks only (not in `run:` shell scripts); validate inputs in composite actions |

## Attack Surface

- GitHub repository `main` branch — direct push protection is the primary gate
- `uses: luukjuh123/gitops-templates/...@main` call sites in all galaxy CI workflows
- `charts/app-base/values.yaml` defaults consumed by every Helm-based deployment
- Helm chart `values.schema.json` — schema enforcement on consumer values
- GitHub Actions workflow inputs from consumer repositories

## Security Controls Already Present

- `.safety-policy.yml` present — indicates Python dependency safety scanning is configured
- `values.schema.json` exists for `app-base`, `cronjob`, and `statefulset` charts — enforces input types
- `kubeconform` validation added to CI lint workflow
- ServiceAccount template exists (separation of workload identity)

## Open Risks

| Risk | Severity | Owner | Notes |
|------|----------|-------|-------|
| No `securityContext` in Deployment template | HIGH | galaxy primary agent | All galaxy workloads run as root by default |
| `image.tag: "latest"` default | HIGH | galaxy primary agent | Non-deterministic deployments across all galaxies |
| Consumers pin to `@main` with no version tag | MEDIUM | galaxy primary agent | Any push to main immediately affects all galaxy CI pipelines |
| Ingress has no TLS enforcement by default | MEDIUM | galaxy primary agent | Plain-HTTP services may be deployed in production |
