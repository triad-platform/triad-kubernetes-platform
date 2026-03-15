# AWS Dev Teardown And Rebuild

This runbook defines the current operator path for intentionally parking the AWS dev environment to control cost, then bringing it back without ad hoc recovery work.

This is a **dev-grade reproducibility runbook**. The current validated operator contract is:

1. rebuild the EKS layer with Terraform
2. refresh kubeconfig
3. run Argo bootstrap

It is still not a zero-touch production bootstrap, but it is now the tested AWS dev recovery path.

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
5. `kubectl` access to the cluster is the primary control path.
   - Do not assume `argocd` CLI RBAC is available.
   - Use `kubectl get/annotate/describe app -n argocd` for reconciliation and diagnostics.

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

This section assumes the current preferred cost-saving boundary:

1. `triad-landing-zones` stays intact
2. only the EKS/platform layer was destroyed

If the landing zone is still present, you do **not** start by re-applying it again. You begin at the EKS layer.

### Step 1: Confirm The Foundation Is Still Intact

These are expected to remain in place:

1. VPC and subnets
2. ECR repositories
3. RDS
4. ElastiCache
5. ACM certificate
6. Route 53 hosted zone and app record
7. SNS topic and confirmed email subscription
8. Secrets Manager values for:
   - database
   - Grafana admin
   - Alertmanager config

This check is mostly administrative. If those are known-good and the landing-zone stack was not destroyed, continue directly to the EKS layer.

### Step 2: Re-Apply The EKS Platform Layer

Apply the EKS layer first:

```bash
cd /Users/lseino/triad-platform/triad-kubernetes-platform/clusters/aws-eks-dev/terraform
terraform plan
terraform apply
```

This should recreate:

1. EKS cluster
2. managed node group
3. EKS managed add-ons
4. IRSA roles from this repo

After apply, verify:

```bash
aws eks describe-cluster \
  --region us-east-1 \
  --name triad-aws-eks-dev \
  --query 'cluster.{version:version,status:status}' \
  --output json

aws eks describe-nodegroup \
  --region us-east-1 \
  --cluster-name triad-aws-eks-dev \
  --nodegroup-name default-20260228232254827600000012 \
  --query 'nodegroup.{version:version,status:status,scaling:scalingConfig}' \
  --output json
```

Current expected dev baseline:

1. Kubernetes version `1.35`
2. node floor `3/3/4`

If version drift is involved, use the helper:

```bash
/Users/lseino/triad-platform/triad-kubernetes-platform/scripts/eks-hop.sh 1.35
```

### Step 3: Restore Cluster Access

Refresh kubeconfig:

```bash
aws eks update-kubeconfig --region us-east-1 --name triad-aws-eks-dev
```

Then verify the cluster is reachable:

```bash
kubectl get nodes
kubectl get pods -A
```

At this point, the cluster exists, but the platform and apps are not yet restored.

### Step 4: Bootstrap ArgoCD And Root Apps (Scripted Default)

Use the helper script as the default bootstrap path:

```bash
/Users/lseino/triad-platform/triad-kubernetes-platform/scripts/bootstrap-argocd.sh
```

What this script does:

1. ensures namespace `argocd` exists
2. installs ArgoCD from the upstream stable manifest using server-side apply
3. waits for ArgoCD pods to become ready
4. verifies `argocd-cm` exists
5. applies `/platform/argocd/root-applications.yaml`

Optional environment overrides:

1. `ARGOCD_NAMESPACE`
2. `ARGOCD_INSTALL_URL`
3. `ROOT_APPS_FILE`
4. `TIMEOUT_SECONDS`

Manual fallback (only if script cannot be used):

```bash
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f /Users/lseino/triad-platform/triad-kubernetes-platform/platform/argocd/root-applications.yaml
```

Then restore operator access if needed:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 --decode; echo
```

### Step 5: Verify Argo Root Applications

Verify Argo sees the applications:

```bash
kubectl get applications -n argocd
```

What should happen next:

1. `triad-platform-apps` and `triad-workload-apps` appear
2. Argo begins reconciling:
   - platform add-ons
   - PulseCart workloads

If root apps do not reconcile to expected child apps, force hard refresh:

```bash
kubectl annotate app triad-platform-apps -n argocd argocd.argoproj.io/refresh=hard --overwrite
kubectl annotate app triad-workload-apps -n argocd argocd.argoproj.io/refresh=hard --overwrite
kubectl get applications -n argocd
```

### Step 6: Let Platform Add-Ons Converge

These should come back through Argo, not manual `kubectl apply`:

1. AWS Load Balancer Controller
2. cert-manager
3. external-dns
4. external-secrets
5. storage baseline
6. observability baseline
7. NATS
8. Kyverno
9. admission policy baseline

Check:

```bash
kubectl get pods -A
kubectl get pvc -n observability
kubectl get storageclass
kubectl get applications -n argocd
```

Specific health checks:

1. `external-dns` should be healthy
2. `external-secrets` should be healthy
3. `gp3` storage class should exist
4. observability PVCs should be `Bound`
5. required `external-secrets` CRDs should exist:

```bash
kubectl get crd externalsecrets.external-secrets.io secretstores.external-secrets.io clustersecretstores.external-secrets.io
```

Current intended GitOps shape:

1. `external-secrets-crds` should reconcile before the `external-secrets` controller app.
2. `external-secrets` chart-side CRD installation should remain disabled once that prereq app exists.
3. The manual CRD recovery block below is fallback-only, not the desired steady-state rebuild path.

If `external-secrets` is healthy but workloads stay `OutOfSync/Missing`, run first-principles checks:

```bash
kubectl get app external-secrets -n argocd
kubectl get app observability-baseline -n argocd
kubectl get app pulsecart-workloads -n argocd
kubectl get ns observability pulsecart
```

Interpretation:

1. If `observability-baseline` and `pulsecart-workloads` show `OutOfSync` + `Missing`
2. and `observability` / `pulsecart` namespaces are not created
3. and Argo reports missing `SecretStore` / `ExternalSecret` kinds

then the root cause is missing CRDs in the destination cluster (most commonly `secretstores.external-secrets.io` and `clustersecretstores.external-secrets.io`).

Fallback recovery (cluster-side, only if the explicit CRD prereq path did not converge):

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm template external-secrets external-secrets/external-secrets \
  --version 0.20.4 \
  --namespace kube-system \
  --set installCRDs=true > /tmp/external-secrets-rendered.yaml

kubectl apply --server-side --force-conflicts -f /tmp/external-secrets-rendered.yaml

kubectl get crd externalsecrets.external-secrets.io secretstores.external-secrets.io clustersecretstores.external-secrets.io

kubectl annotate app external-secrets-prereqs -n argocd argocd.argoproj.io/refresh=hard --overwrite
kubectl annotate app external-secrets -n argocd argocd.argoproj.io/refresh=hard --overwrite
kubectl annotate app observability-baseline -n argocd argocd.argoproj.io/refresh=hard --overwrite
kubectl annotate app pulsecart-workloads -n argocd argocd.argoproj.io/refresh=hard --overwrite
kubectl get applications -n argocd
```

Admission enforcement verification:

```bash
kubectl get pods -n kyverno
kubectl get clusterpolicies.kyverno.io

kubectl apply -f /Users/lseino/triad-platform/triad-ci-security/policy/admission/tests/pod-deny-unapproved-registry.yaml
kubectl apply -f /Users/lseino/triad-platform/triad-ci-security/policy/admission/tests/pod-deny-missing-labels.yaml
```

Expected:

1. both deny test applies are rejected by admission webhook
2. rejection message references policy rule violations

Kyverno-specific recovery branch (if `kyverno` shows `OutOfSync/Missing`):

```bash
kubectl create namespace kyverno --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f /Users/lseino/triad-platform/triad-kubernetes-platform/apps/platform/kyverno.yaml
kubectl apply -f /Users/lseino/triad-platform/triad-kubernetes-platform/apps/platform/admission-policy-baseline.yaml
kubectl annotate app kyverno -n argocd argocd.argoproj.io/refresh=hard --overwrite
kubectl annotate app admission-policy-baseline -n argocd argocd.argoproj.io/refresh=hard --overwrite
kubectl get applications -n argocd
```

If namespace deletion hangs during cleanup, clear finalizers:

```bash
kubectl get ns kyverno -o json | jq 'del(.spec.finalizers)' | kubectl replace --raw /api/v1/namespaces/kyverno/finalize -f -
```

### Step 7: Let Workloads Converge

The workload app should restore:

1. `api-gateway`
2. `orders`
3. `worker`
4. `notifications`
5. `SecretStore`
6. `ExternalSecret`
7. `Ingress`

Check:

```bash
kubectl get applications -n argocd
kubectl get pods -n pulsecart
kubectl get ingress -n pulsecart
```

Expected:

1. `pulsecart-workloads` is `Synced` and `Healthy`
2. all four workloads are `Running`
3. ingress has an address

### Step 8: Verify Public Path, Smoke, And Observability

Run the minimum operator validation:

```bash
curl -i https://pulsecart-dev.cloudevopsguru.com/healthz
```

Then confirm the normal pipeline validation path is still valid:

1. `triad-kubernetes-platform / E2E Cloud Smoke` can be run manually if needed
2. a normal app change should still trigger:
   - build
   - GitOps overlay promotion
   - Argo reconciliation
   - required async cloud smoke

For direct cluster validation:

```bash
kubectl get pods -n observability
kubectl logs -n observability deployment/alertmanager --tail=50
kubectl logs -n observability deployment/prometheus --tail=50
```

The rebuild is only considered complete when all are true:

1. Argo apps are healthy
2. platform add-ons are healthy
3. workloads are healthy
4. public health endpoint responds
5. observability is healthy
6. async cloud smoke passes

Validated note:

1. After the explicit `external-secrets-crds` prereq app was added and the workload labels were fixed in `triad-app`, this rebuild path was re-tested successfully.
2. The expected operator flow is now `terraform apply -> aws eks update-kubeconfig -> bootstrap-argocd.sh -> validation checks`.

## What Is Automated Versus Manual Today

### Automated After Bootstrap

Once the cluster exists and Argo is installed:

1. platform add-ons reconcile from git
2. workload manifests reconcile from git
3. `external-dns` maintains the public app record
4. `external-secrets` restores runtime secrets into the cluster
5. CI promotes live workload images through the GitOps overlay
6. Argo reconciles those workload image changes
7. required cloud smoke validates the deployed path

### Still Manual By Design

These are the current operator steps that are **not** yet fully automated:

1. initial ArgoCD installation
2. operator login / port-forward for ArgoCD
3. initial GitHub secret setup
4. SNS email subscription confirmation
5. explicit Terraform apply and destroy operations

These are the exact gaps to smooth further before calling the process zero-touch.

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

## Exit Condition Before Additional Clouds

AWS is considered "ready enough" for Azure parity first, and then GCP parity after Azure, when:

1. this runbook can be followed without surprise recovery work
2. the environment can be parked and rebuilt predictably
3. the normal CI -> GitOps -> Argo -> smoke path still works after rebuild

That is the standard Azure should mirror first.
