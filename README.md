# triad-kubernetes-platform

GitOps-managed Kubernetes platform layer (EKS + AKS).
- cluster bootstrapping references
- platform add-ons (ArgoCD, ingress, cert-manager, policies, observability)
- app-of-apps patterns

Start here: platform/argocd/README.md

Current Phase 2 starting points:
- `clusters/aws-eks-dev/`
  - dev cluster input contract and first EKS Terraform root
- `platform/`
  - ALB controller + external-dns + external-secrets IRSA contracts and first in-cluster NATS manifests
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
