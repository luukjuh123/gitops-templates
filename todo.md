# GitOps Templates -- Todo

## Priority: High
- [ ] Create base Helm chart structure (`charts/app-base/Chart.yaml`, `values.yaml`, `_helpers.tpl`)
- [ ] Write Deployment template (`charts/app-base/templates/deployment.yaml`)
- [x] Write Service template (`charts/app-base/templates/service.yaml`) -- PR #17
- [x] Write Ingress template (`charts/app-base/templates/ingress.yaml`) -- PR #TBD
- [x] Create base Helm chart structure (`charts/app-base/Chart.yaml`, `values.yaml`, `_helpers.tpl`) -- PR #8
- [x] Write Deployment template (`charts/app-base/templates/deployment.yaml`)
- [ ] Write Service template (`charts/app-base/templates/service.yaml`)
- [x] Write Ingress template (`charts/app-base/templates/ingress.yaml`) -- PR
- [ ] Write HPA template (`charts/app-base/templates/hpa.yaml`)
- [ ] Write ConfigMap template (`charts/app-base/templates/configmap.yaml`)
- [ ] Write ServiceAccount template (`charts/app-base/templates/serviceaccount.yaml`)
- [ ] Create `values.schema.json` for the base chart
- [x] Add GitHub Actions lint workflow (`.github/workflows/lint.yml`) -- PR #4
- [ ] Update all 19 galaxy CI workflows to reference gitops-templates reusable workflows (instead of inline checks)
- [x] Add Kustomize base as alternative to Helm -- feat/kustomize-base

## Priority: Medium
- [ ] Create example consumer values file (`examples/service-values.yaml`)
- [x] Add kubeval/kubeconform validation to CI workflow
- [x] Create Kustomize base as alternative to Helm (`kustomize/base/`) <!-- PR #TBD -->

## Priority: Low
- [x] Add chart versioning and release workflow -- PR #6
- [x] Create additional chart variants (CronJob, StatefulSet) -- PR #15
- [x] Add Helm chart repository index for proper `helm repo add` support -- PR #7

## Completed
<!-- [x] Task description -- PR #N -->
