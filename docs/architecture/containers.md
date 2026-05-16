# Containers — gitops-templates

```mermaid
C4Container
  title Containers — gitops-templates

  Person(engineer, "gitops-engineer")

  System_Boundary(gitops, "gitops-templates Repository") {
    Container(workflows, "Reusable Workflows (.github/workflows/)", "GitHub Actions YAML", "12 reusable workflows: python-quality, python-test, rust-quality, rust-test, rust-build, typescript-quality, typescript-test, typescript-build, helm-lint, helm-release, terraform-validate, docker-build")
    Container(actions, "Composite Actions (.github/actions/)", "GitHub Actions composite", "setup-python (uv), setup-rust (toolchain + cache), setup-node (npm ci), setup-helm (helm + kubeconform), setup-terraform (tflint)")
    Container(ci_templates, "CI Templates (ci/)", "GitHub Actions YAML", "Standalone CI files for Python, Rust, TypeScript — copied by Genesis into new galaxy repos at bootstrap")
    Container(helm_charts, "Helm Charts (charts/)", "Helm / Kubernetes YAML", "app-base: Deployment, Service, Ingress, HPA, ConfigMap, ServiceAccount templates with values.schema.json. (cronjob + statefulset: TBD)")
    Container(scripts, "Scripts (scripts/)", "Bash", "Reusable shell scripts: helm/, terraform/, kubernetes/, docker/ categories")
    Container(examples, "Examples (examples/)", "YAML", "Usage examples: service-values.yaml showing how to override app-base values")
  }

  System_Ext(galaxy_repos, "Calling Galaxy Repos")
  System_Ext(kubernetes, "Kubernetes Cluster")

  Rel(engineer, workflows, "Adds / updates workflow YAML")
  Rel(engineer, helm_charts, "Adds / updates chart templates")
  Rel(galaxy_repos, workflows, "uses: path@main in caller workflows")
  Rel(galaxy_repos, actions, "uses: path@main in caller workflows")
  Rel(galaxy_repos, helm_charts, "helm upgrade --install via chart URL")
  Rel(helm_charts, kubernetes, "Rendered manifests applied to cluster")
```

## Description
The repository is structured as a library with no runtime process of its own. Reusable workflows and composite actions are invoked by calling galaxy repos at CI time. Helm charts are either referenced directly or packaged by the helm-release workflow and published for consumption.
