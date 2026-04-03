# GitOps Templates -- Todo

## Priority: High
- [x] Create base Helm chart structure (`charts/app-base/Chart.yaml`, `values.yaml`, `_helpers.tpl`) -- PR #8
- [ ] Write Deployment template (`charts/app-base/templates/deployment.yaml`)
- [x] Write Service template (`charts/app-base/templates/service.yaml`)
- [ ] Write Ingress template (`charts/app-base/templates/ingress.yaml`)
- [ ] Write HPA template (`charts/app-base/templates/hpa.yaml`)
- [x] Write ConfigMap template (`charts/app-base/templates/configmap.yaml`) -- PR #3
- [ ] Write ServiceAccount template (`charts/app-base/templates/serviceaccount.yaml`)
- [ ] Create `values.schema.json` for the base chart
- [x] Add GitHub Actions lint workflow (`.github/workflows/lint.yml`) -- PR #4
- [ ] Update all 19 galaxy CI workflows to reference gitops-templates reusable workflows (instead of inline checks)
- [ ] Add Kustomize base as alternative to Helm

## Priority: Medium
- [x] Create example consumer values file (`examples/service-values.yaml`) -- PR #5
- [x] Add kubeval/kubeconform validation to CI workflow
- [ ] Create Kustomize base as alternative to Helm (`kustomize/base/`)
- [ ] Add Docker build + push reusable workflow
- [x] Add helm-release reusable workflow -- PR #14

## Priority: Low
- [x] Add chart versioning and release workflow -- PR #6
- [x] Create additional chart variants (CronJob, StatefulSet) -- PR #15
- [x] Add Helm chart repository index for proper `helm repo add` support -- PR #7

## Completed
<!-- [x] Task description -- PR #N -->
