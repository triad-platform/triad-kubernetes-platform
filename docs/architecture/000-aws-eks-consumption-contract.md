# AWS EKS Consumption Contract (Phase 2)

This document defines what the Kubernetes platform layer expects from `triad-landing-zones` and what it must provide to deploy the PulseCart Phase 1 vertical slice.

## Upstream Inputs From triad-landing-zones

The EKS layer expects these outputs from the dev landing zone:

1. `vpc_id`
2. `eks_cluster_subnet_ids`
3. `ingress_public_subnet_ids`
4. `availability_zones`
5. `rds_subnet_candidate_ids`
6. `elasticache_subnet_candidate_ids`

These are produced by:

- `/Users/lseino/triad-platform/triad-landing-zones/envs/dev/outputs.tf`

## Required EKS Inputs

Minimum cluster build inputs:

1. cluster name
2. AWS region
3. VPC ID
4. private subnet IDs for nodes/control-plane attachments
5. public subnet IDs for ingress/load balancers
6. Kubernetes version

## Phase 2 Platform Deliverables

The Kubernetes platform layer must deliver:

1. one dev EKS cluster
2. ArgoCD installed
3. root app-of-apps entrypoint
4. platform add-on reconciliation path
5. app workload reconciliation path

The current implementation now includes:

1. `clusters/aws-eks-dev/terraform`
   - first EKS Terraform root
2. `platform/ingress`
   - AWS Load Balancer Controller IRSA service account contract
3. `platform/nats`
   - first in-cluster NATS Deployment + Service path
4. `platform/external-dns`
   - external-dns IRSA service account contract for Route 53 automation

Subnet ownership model for this phase:

1. `triad-landing-zones` creates the shared subnets
2. `triad-landing-zones` applies the Kubernetes discovery tags required by EKS and ALB
3. `triad-kubernetes-platform` consumes already tagged subnet IDs

This is the cleaner standard because the cluster repo does not mutate shared network primitives.

## First Add-On Set

Keep the first set intentionally small:

1. ArgoCD
2. AWS Load Balancer Controller (ALB)
3. cert-manager
4. external-dns
5. external-secrets
6. metrics scrape baseline
7. NATS

Deferred:

1. service mesh
2. policy webhooks
3. cluster autoscaling optimization

## Concrete Phase 2 Runtime Targets

This repo should assume the following first deployment model:

1. RDS PostgreSQL is AWS-managed and external to the cluster
2. ElastiCache Redis is AWS-managed and external to the cluster
3. NATS remains self-hosted in-cluster
4. Public entry uses ALB, not NGINX
5. First dev DNS host is `pulsecart-dev.cloudevopsguru.com`

## Application Runtime Expectations

The application contract remains defined by:

- `/Users/lseino/triad-platform/triad-app/docs/deployment/000-aws-first-deployment-contract.md`

This repo consumes that contract and converts it into:

1. namespaces
2. Deployments
3. Services
4. Ingress
5. ConfigMaps and Secrets
6. environment overlays that pin the live image refs ArgoCD reconciles

## Phase 2 Success Criteria (Platform Layer)

The platform layer is ready when:

1. cluster bootstrap inputs are fully defined
2. ArgoCD can reconcile root applications
3. there is a deterministic path for platform and workload manifests
4. the app repo can be deployed without changing runtime assumptions
