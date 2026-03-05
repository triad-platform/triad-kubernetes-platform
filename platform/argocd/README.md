# ArgoCD Bootstrap

This folder will contain the GitOps bootstrap for ArgoCD (app-of-apps).

## Phase 2 Goal

Bootstrap ArgoCD so the AWS-first PulseCart deployment can be reconciled from git.

## Minimum Bootstrap Deliverables

1. ArgoCD installation manifests or Helm values
2. Root applications for platform add-ons and app workloads
3. A mix of Helm-backed and repo-path-backed Application definitions

## Contract

The workloads being deployed are defined by:

- `/Users/lseino/triad-platform/triad-app/docs/deployment/000-aws-first-deployment-contract.md`

The cluster/runtime standards are defined by:

- `/Users/lseino/triad-platform/triad-kubernetes-platform/docs/platform-standards/000-standards.md`

## First App-of-Apps Shape

Recommended initial split:

1. `apps/platform`
   - AWS Load Balancer Controller
   - cert-manager
   - external-dns
   - external-secrets
   - metrics scraping baseline
   - NATS

2. `apps/workloads`
   - workload `Application` definitions
   - these now point at platform-owned environment overlays (for example `workloads/pulsecart/dev`) instead of pointing directly at app repos

Current bootstrap starter:

- `root-applications.yaml`
  - contains the initial Application objects for:
    - `apps/platform`
    - `apps/workloads`
- `/Users/lseino/triad-platform/triad-kubernetes-platform/scripts/bootstrap-argocd.sh`
  - scripted bootstrap path that installs ArgoCD, waits for readiness, verifies `argocd-cm`, and applies root applications

Current platform app split:

1. `aws-load-balancer-controller`
   - Helm chart source
   - uses a pre-created IRSA-enabled service account in `platform/ingress`
2. `cert-manager`
   - Helm chart source
3. `nats`
   - repo path `platform/nats`
4. `external-dns`
   - Helm chart source
   - uses a pre-created IRSA-enabled service account in `platform/external-dns`
5. `external-secrets`
   - Helm chart source
   - uses a pre-created IRSA-enabled service account in `platform/external-secrets`
6. `observability-baseline`
   - repo path `platform/observability`

Note:
- Phase 2 public entry should ultimately resolve `pulsecart-dev.cloudevopsguru.com` through ALB to `api-gateway`.
- After the first manual Route 53 bootstrap, `external-dns` is the intended automation path for keeping that record in sync.
- ArgoCD becomes the normal in-cluster reconciler after bootstrap.
- The preferred bootstrap path is now scripted; manual kubectl install commands are fallback only.
