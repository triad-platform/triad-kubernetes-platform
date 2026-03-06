# triad-kubernetes-platform

GitOps-managed Kubernetes platform layer (EKS + AKS + GKE).
- cluster bootstrapping references
- platform add-ons (ArgoCD, ingress, cert-manager, policies, observability)
- app-of-apps patterns

Start here: platform/argocd/README.md
Day-2 translation guide: docs/runbooks/multi-cloud-day2-translation-cheatsheet.md

Current Phase 2 starting points:
- `clusters/aws-eks-dev/`
  - dev cluster input contract and first EKS Terraform root
- `clusters/azure-aks-dev/`
  - AKS dev cluster Terraform root consuming Azure landing-zone outputs
- `clusters/gcp-gke-dev/`
  - GKE dev cluster Terraform root consuming GCP landing-zone outputs
- `modules/azure/aks/`
  - reusable AKS cluster module used by the Azure dev cluster root
- `modules/gcp/gke/`
  - reusable GKE cluster module used by the GCP dev cluster root
- `platform/`
  - ALB controller + external-dns + external-secrets IRSA contracts, in-cluster NATS, and admission enforcement baseline (Kyverno + policy app)
- `apps/platform/` and `apps/workloads/`
  - first ArgoCD application split with Helm + Kustomize sources
- `workloads/pulsecart/dev/`
  - dev GitOps overlay that pins the live workload image refs ArgoCD reconciles
  - the platform repo now also owns the automatic cloud smoke workflow for deploy-state changes
  - that smoke now validates both the public request contract and the async worker/notification completion path
- `platform/observability/`
  - real in-cluster Prometheus + Grafana dev baseline managed by ArgoCD
  - starter dashboard and alert rules are deployed here, not just documented
  - persistent PVC-backed storage and a baseline Alertmanager are now part of the dev stack
  - Grafana admin and Alertmanager receiver config now use Kubernetes secrets instead of inline defaults
  - `external-secrets` can now merge AWS-backed values into those observability secrets for a non-breaking migration
- `platform/storage/`
  - cluster storage baseline with a default CSI-backed `gp3` `StorageClass`
- `scripts/`
  - operational helpers such as `eks-hop.sh` for one-minor-version EKS upgrades with add-on and nodegroup checks
- `docs/runbooks/`
  - operational runbooks, including the current AWS dev teardown/rebuild path

Operational note:
- The AWS dev cluster is now intended to be reproducible enough that it can be intentionally scaled down or torn down between active work periods to control cost, then brought back through the normal Terraform + ArgoCD flow.
- That makes it a strong dev reference baseline, but not a production-grade platform yet.

Phase 5 operator runbook:
- `docs/runbooks/phase5-azure-gcp-bootstrap.md`
  - step-by-step path to bring up Azure + GCP baselines and AKS/GKE clusters
