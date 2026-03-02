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
