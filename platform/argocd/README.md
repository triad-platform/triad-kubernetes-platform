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
   - metrics scraping baseline
   - NATS

2. `apps/workloads`
   - api-gateway
   - orders
   - worker
   - notifications

Current bootstrap starter:

- `root-applications.yaml`
  - contains the initial Application objects for:
    - `apps/platform`
    - `apps/workloads`

Current platform app split:

1. `aws-load-balancer-controller`
   - Helm chart source
   - uses a pre-created IRSA-enabled service account in `platform/ingress`
2. `cert-manager`
   - Helm chart source
3. `nats`
   - repo path `platform/nats`
4. `observability-baseline`
   - repo path `platform/observability`

Note:
- Phase 2 public entry should ultimately resolve `pulsecart-dev.cloudevopsguru.com` through ALB to `api-gateway`.
