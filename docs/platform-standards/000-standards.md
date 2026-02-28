# Platform Standards

Phase 2 platform standards define the minimum runtime expectations for deploying the PulseCart vertical slice to EKS.

## Source Contract

Application/runtime expectations are defined in:

- `/Users/lseino/triad-platform/triad-app/docs/deployment/000-aws-first-deployment-contract.md`

## Phase 2 Minimum Standards

1. Namespaces
   - one dedicated app namespace for PulseCart workloads

2. Workload shape
   - one Deployment per service
   - one ClusterIP Service per HTTP service
   - one dedicated metrics endpoint per instrumented workload

3. Ingress
   - external ingress terminates at `api-gateway`
   - internal service-to-service traffic remains cluster-local

4. Runtime config
   - environment variables delivered via ConfigMap/Secret split
   - no environment-specific values hardcoded in manifests

5. Health and rollout
   - `/healthz` and `/readyz` drive probes for HTTP services
   - worker rollout must not drop metrics visibility

6. Metrics
   - gateway, orders, and worker `/metrics` must be scrapeable

## Deferred Standards

These are intentionally deferred until later phases:

1. advanced policy enforcement
2. service mesh
3. multi-tenant namespace policy
4. production-grade secret rotation
