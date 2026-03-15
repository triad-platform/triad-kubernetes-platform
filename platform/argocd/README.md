# ArgoCD Bootstrap

This folder will contain the GitOps bootstrap for ArgoCD (app-of-apps).

## Goal

Bootstrap ArgoCD so the PulseCart platform and workloads can be reconciled from git across AWS, Azure, and GCP clusters.

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
   - cloud-specific platform app trees (`apps/platform`, `apps/platform/azure`, `apps/platform/gcp`)
   - AWS keeps the ALB controller path
   - Azure and GCP use ingress-nginx for the first parity rollout
   - all clouds keep cert-manager, external-dns, external-secrets, Kyverno, NATS, observability, and storage baselines

2. `apps/workloads`
   - workload `Application` definitions
   - AWS continues to use `workloads/pulsecart/dev`
   - Azure now points at `workloads/pulsecart/azure-dev`
   - GCP now points at `workloads/pulsecart/gcp-dev`

Current bootstrap starter:

- `root-applications.yaml`
  - AWS root applications
- `root-applications-azure.yaml`
  - Azure root applications
- `root-applications-gcp.yaml`
  - GCP root applications
- `/Users/lseino/triad-platform/triad-kubernetes-platform/scripts/bootstrap-argocd.sh`
  - scripted bootstrap path that installs ArgoCD, waits for readiness, verifies `argocd-cm`, and applies the root applications selected by `ROOT_APPS_FILE`

Current AWS platform app split:

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
6. `external-secrets-crds`
   - repo path from the upstream `external-secrets` Git repo
   - exists to make CRD availability a first-class prereq on blank-cluster bootstrap
7. `observability-baseline`
   - repo path `platform/observability`

Note:
- Phase 2 public entry should ultimately resolve `pulsecart-dev.cloudevopsguru.com` through ALB to `api-gateway`.
- After the first manual Route 53 bootstrap, `external-dns` is the intended automation path for keeping that record in sync.
- The AWS path now treats `external-secrets` CRDs as an explicit prereq app instead of relying only on Helm chart CRD timing.
- The Azure and GCP parity paths now have dedicated root app files and workload overlays, but still require real cloud-specific secret values, DNS credentials, and registry/image promotion wiring before smoke can pass.
- ArgoCD becomes the normal in-cluster reconciler after bootstrap.
- The preferred bootstrap path is now scripted; manual kubectl install commands are fallback only.
