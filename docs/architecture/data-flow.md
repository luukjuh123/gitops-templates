# Data Flow — gitops-templates

```mermaid
flowchart TD
    subgraph GalaxyCI ["Galaxy Repo CI (GitHub Actions caller)"]
        GalaxyCIFile[Galaxy .github/workflows/ci.yml\nuses: luukjuh123/gitops-templates/.github/workflows/python-test.yml@main]
    end

    subgraph gitopsTemplates ["gitops-templates Repo"]
        RWF[Reusable Workflow\n.github/workflows/python-test.yml\nstep: uses setup-python action\nstep: pytest --cov]
        CA[Composite Action\n.github/actions/setup-python\ninstalls Python + uv + deps]
        Charts[Helm Chart\ncharts/app-base/\nDeployment + Service + Ingress + HPA]
    end

    subgraph GitHubActions ["GitHub Actions Runner"]
        Runner([GitHub-hosted runner])
    end

    subgraph Kubernetes ["Kubernetes Cluster"]
        K8s([kubectl apply\nhelm upgrade --install])
    end

    GalaxyCIFile -->|triggers| Runner
    Runner -->|fetches workflow definition| RWF
    RWF -->|calls| CA
    CA -->|sets up Python env on runner| Runner
    RWF -->|runs pytest| Runner
    Runner -->|test results| GalaxyCIFile

    GalaxyCIFile2[Galaxy Deploy Workflow\nhelm upgrade --install\nfrom charts/app-base] -->|helm render + apply| K8s
    Charts -->|referenced by| GalaxyCIFile2
```

## Description
The data flow is pull-based: galaxy CI workflows reference gitops-templates by path at a specific git ref (`@main`). GitHub Actions fetches the referenced workflow/action definition and executes it on the runner. Helm charts are consumed by galaxy deploy jobs which render values against the base chart and apply to Kubernetes.
