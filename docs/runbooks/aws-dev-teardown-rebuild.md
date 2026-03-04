# AWS Dev Teardown And Rebuild

This runbook defines the current operator path for intentionally parking the AWS dev environment to control cost, then bringing it back without ad hoc recovery work.

This is a **dev-grade reproducibility runbook**, not a zero-touch environment bootstrap.

## Scope

This covers:

1. pausing or tearing down the active AWS dev platform
2. recreating it from the normal Terraform + ArgoCD + CI flow
3. identifying the remaining manual bootstrap steps that still exist by design

## Preconditions

Before teardown or rebuild:

1. AWS credentials are available locally
2. `kubectl`, `terraform`, `aws`, `argocd`, `helm`, and `jq` are installed
3. GitHub repo secrets that the platform depends on already exist
   - example: `TRIAD_PLATFORM_GITOPS_PAT` in `triad-app`
4. The operator can still access:
   - Route 53
   - ECR
   - EKS
   - Secrets Manager

## What Can Be Safely Parked

The AWS dev environment is now stable enough that it does not need to stay online continuously.

You can intentionally scale down or tear down:

1. EKS worker capacity
2. in-cluster platform and workload resources
3. the EKS cluster itself if needed

The following are typically kept unless you intentionally want a fuller rebuild:

1. landing-zone networking
2. ECR repositories
3. Route 53 hosted zone
4. ACM certificates
5. Secrets Manager secrets

## Low-Cost Parking Option (Preferred First)

If the goal is cost reduction without a full rebuild:

1. Scale the EKS managed node group down to zero or the lowest acceptable dev floor
2. Leave the control plane and managed dependencies in place
3. Accept that EKS control-plane cost still continues

This is the lower-risk option, but it does **not** remove the EKS control-plane charge.

## Full Teardown Boundary

If the goal is maximum cost reduction:

1. Destroy the EKS stack in `triad-kubernetes-platform`
2. Optionally leave `triad-landing-zones` intact so:
   - networking
   - ECR
   - RDS
   - ElastiCache
   - ACM
   - SNS
   remain as stable dependencies

This is the current recommended teardown line for dev:

1. keep `triad-landing-zones`
2. tear down `triad-kubernetes-platform`
3. preserve GitOps repos and CI configuration

That gives meaningful cost reduction while keeping the rebuild path straightforward.

## Teardown Order

### Option A: Park Capacity

1. Reduce the node group with Terraform in:
   - `triad-kubernetes-platform/clusters/aws-eks-dev/terraform`
2. Keep the cluster alive
3. Confirm platform workloads are intentionally scaled down or unschedulable

### Option B: Full Platform Teardown

1. Confirm the current Git state is merged and documented
2. In:
   - `triad-kubernetes-platform/clusters/aws-eks-dev/terraform`
   run a normal destroy flow for the EKS layer
3. Verify:
   - EKS cluster deleted
   - EBS volumes released according to normal AWS behavior
4. Leave `triad-landing-zones/envs/dev` intact unless you intentionally want to rebuild the entire cloud foundation

## Rebuild Order

### Step 1: Backend And Landing Zone

1. Ensure the Terraform backend exists:
   - `triad-landing-zones/bootstrap/aws-tf-backend`
2. Apply or re-apply:
   - `triad-landing-zones/envs/dev`

This restores:

1. VPC and subnets
2. ECR
3. GitHub OIDC for CI
4. RDS
5. ElastiCache
6. ACM
7. SNS topic and email subscription

### Step 2: EKS Platform Layer

1. Apply:
   - `triad-kubernetes-platform/clusters/aws-eks-dev/terraform`
2. Confirm:
   - cluster exists
   - node group exists
   - add-ons are healthy

If Kubernetes version drift is involved, use:

```bash
/Users/lseino/triad-platform/triad-kubernetes-platform/scripts/eks-hop.sh <target-version>
```

### Step 3: Cluster Access

1. Refresh kubeconfig:

```bash
aws eks update-kubeconfig --region us-east-1 --name triad-aws-eks-dev
```

2. Confirm access:

```bash
kubectl get nodes
```

### Step 4: ArgoCD Bootstrap

This is still a one-time manual bootstrap step in the current model.

1. Install ArgoCD into the cluster
2. Port-forward and log in
3. Apply:
   - `triad-kubernetes-platform/platform/argocd/root-applications.yaml`

After that, Argo should own:

1. platform add-ons
2. workload reconciliation

### Step 5: Secrets And Controllers

The following must already exist and be valid:

1. AWS Secrets Manager values for:
   - database
   - Grafana admin
   - Alertmanager config
2. IRSA roles must already be created by Terraform

Then allow Argo + `external-secrets` to converge.

### Step 6: Validation

Run these in order:

1. `argocd app list`
2. `kubectl get pods -A`
3. `kubectl get pvc -n observability`
4. public health check
5. required cloud smoke

The rebuild is only considered complete when:

1. Argo is healthy
2. workloads are healthy
3. observability is healthy
4. async cloud smoke passes

## Remaining Manual Steps (Still Expected)

These are not bugs. They are current bootstrap boundaries:

1. Terraform backend bootstrap
2. Initial ArgoCD installation
3. GitHub repository/org secret setup
4. SNS email subscription confirmation
5. Human operator access to AWS and the cluster

## What Is Still Not Production-Grade

This environment is a hardened dev reference, not a production platform.

Examples of intentionally non-production aspects:

1. single-replica observability components
2. manual ArgoCD first install
3. admin access still relies on operator-driven port-forward paths
4. no fully automated org-wide credential brokering yet
5. no true high-availability data-plane posture inside the cluster

## Exit Condition Before Azure

AWS is considered "ready enough" for Azure parity when:

1. this runbook can be followed without surprise recovery work
2. the environment can be parked and rebuilt predictably
3. the normal CI -> GitOps -> Argo -> smoke path still works after rebuild

That is the standard Azure should mirror first.
