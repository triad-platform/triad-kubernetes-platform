# ArgoCD Bootstrap

This folder will contain the GitOps bootstrap for ArgoCD (app-of-apps).

## Phase 2 Goal

Bootstrap ArgoCD so the AWS-first PulseCart deployment can be reconciled from git.

## Minimum Bootstrap Deliverables

1. ArgoCD installation manifests or Helm values
2. Root applications for platform add-ons and app workloads

## Contract

The workloads being deployed are defined by:

- `/Users/lseino/triad-platform/triad-app/docs/deployment/000-aws-first-deployment-contract.md`

The cluster/runtime standards are defined by:

- `/Users/lseino/triad-platform/triad-kubernetes-platform/docs/platform-standards/000-standards.md`

## First App-of-Apps Shape

Recommended initial split:

1. `apps/platform`
   - ingress
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

Note:
- `repoURL` values are placeholders and should be replaced with the real repository remotes before bootstrap.
