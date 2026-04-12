# System Context — gitops-templates

```mermaid
C4Context
  title System Context — gitops-templates

  Person(engineer, "Galaxy Agent / Engineer", "References gitops-templates for CI/CD workflows, Helm charts, composite actions, and scripts when bootstrapping or working in a galaxy")

  System(gitops, "gitops-templates", "Atlas DevOps template library. Single source of truth for reusable GitHub Actions workflows, composite actions, Helm charts (app-base, cronjob, statefulset), Kustomize bases, and utility scripts across all Atlas galaxies.")

  System_Ext(github_actions, "GitHub Actions", "Executes reusable workflows referenced via uses: luukjuh123/gitops-templates/.github/workflows/*@main")
  System_Ext(kubernetes, "Kubernetes Cluster", "Deploys application workloads rendered from the app-base Helm chart")
  System_Ext(chart_releaser, "Chart Releaser (cr)", "Packages and publishes Helm chart releases to GitHub Pages")
  System_Ext(galaxy_repos, "Galaxy Repositories", "All Atlas galaxy repos reference gitops-templates for CI/CD and Helm deployment")

  Rel(engineer, gitops, "Maintains templates; adds new workflow/chart variants")
  Rel(galaxy_repos, gitops, "Reference via uses: path@main (workflows + actions)", "GitHub Actions")
  Rel(gitops, github_actions, "Reusable workflow definitions executed on caller repos")
  Rel(gitops, chart_releaser, "Releases Helm charts to GitHub Pages", "cr tool")
  Rel(github_actions, kubernetes, "helm upgrade --install from released charts", "kubectl / Helm")
```

## Description
gitops-templates is a shared library repository. It is not deployed itself — galaxies pull from it at CI/CD runtime. The Helm charts it contains are consumed by galaxy deployment workflows and applied to Kubernetes clusters.
