# Phase 5 Azure + GCP Bootstrap

This runbook is the operator path to stand up Azure and GCP baselines after AWS is green.

## Scope

1. Apply Azure landing zone
2. Apply AKS cluster
3. Apply GCP landing zone
4. Apply GKE cluster
5. Confirm kubeconfig access for both clusters
6. Hand off to GitOps/bootstrap and workload deployment on both clusters

## Prerequisites (Operator)

1. Terraform `>= 1.6`
2. Azure CLI authenticated (`az login`)
3. Google Cloud SDK authenticated (`gcloud auth application-default login`)
4. Cloud-side permissions to create networking, managed Kubernetes, registry, and identity resources

## Step 0: Bootstrap Remote State Backends (One-Time)

### 0A) Azure backend bootstrap

```bash
cd /Users/lseino/triad-platform/triad-landing-zones/bootstrap/azure-tf-backend
cp terraform.tfvars.example terraform.tfvars
# set subscription_id and tenant_id
terraform init
terraform plan
terraform apply
```

Capture:

1. `resource_group_name`
2. `storage_account_name`
3. `container_name`

### 0B) GCP backend bootstrap

```bash
cd /Users/lseino/triad-platform/triad-landing-zones/bootstrap/gcp-tf-backend
cp terraform.tfvars.example terraform.tfvars
# set project_id and a globally unique state_bucket_name
terraform init
terraform plan
terraform apply
```

Capture:

1. `state_bucket_name`

## Step 1: Azure Landing Zone

```bash
cd /Users/lseino/triad-platform/triad-landing-zones/azure/envs/dev
cp backend.hcl.example backend.hcl
# set storage_account_name from Step 0A output
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your real subscription/tenant and any CIDR overrides
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

Copy these output values for Step 2:

1. `subscription_id`
2. `tenant_id`
3. `resource_group_name`
4. `aks_subnet_id`
5. `ingress_subnet_id`
6. `container_registry_id`

## Step 2: AKS Cluster

```bash
cd /Users/lseino/triad-platform/triad-kubernetes-platform/clusters/azure-aks-dev/terraform
cp backend.hcl.example backend.hcl
# set storage_account_name from Step 0A output
cp terraform.tfvars.example terraform.tfvars
# paste values from Azure landing-zone outputs
# set kubernetes_version from the current supported list:
# az aks get-versions --location <location> --query "orchestrators[?isPreview==null||isPreview==\`false\`].orchestratorVersion" -o tsv
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

Then configure local kubeconfig:

```bash
az aks get-credentials \
  --resource-group <resource_group_name> \
  --name <cluster_name> \
  --overwrite-existing
kubectl config current-context
```

## Step 3: GCP Landing Zone

```bash
cd /Users/lseino/triad-platform/triad-landing-zones/gcp/envs/dev
cp backend.hcl.example backend.hcl
# set bucket from Step 0B output
cp terraform.tfvars.example terraform.tfvars
# set project_id and region, adjust CIDRs only if needed
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

Copy these output values for Step 4:

1. `project_id`
2. `region`
3. `vpc_name`
4. `gke_subnet_name`
5. `pods_secondary_range_name`
6. `services_secondary_range_name`

## Step 4: GKE Cluster

```bash
cd /Users/lseino/triad-platform/triad-kubernetes-platform/clusters/gcp-gke-dev/terraform
cp backend.hcl.example backend.hcl
# set bucket from Step 0B output
cp terraform.tfvars.example terraform.tfvars
# paste values from GCP landing-zone outputs
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

Then configure local kubeconfig:

```bash
gcloud container clusters get-credentials <cluster_name> \
  --region <region> \
  --project <project_id>
kubectl config current-context
```

## Expected Outcome

1. Azure and GCP network + registry baselines exist
2. AKS and GKE clusters are reachable from local kubeconfig
3. The next execution step is to bootstrap ArgoCD, deploy shared platform add-ons, and roll out PulseCart workloads on both clusters

## Step 5: Bootstrap ArgoCD On AKS

```bash
ROOT_APPS_FILE=/Users/lseino/triad-platform/triad-kubernetes-platform/platform/argocd/root-applications-azure.yaml \
  /Users/lseino/triad-platform/triad-kubernetes-platform/scripts/bootstrap-argocd.sh
```

Follow-up edits before sync is expected to become healthy:

1. Replace Azure Workload Identity placeholders under `platform/external-dns-azure/` and `platform/external-secrets-azure/`.
2. Set the real ACR login server and database/cache values in `workloads/pulsecart/azure-dev/`.
3. Replace the placeholder `DB_PASSWORD` secret value in `workloads/pulsecart/azure-dev/db-password-secret.yaml`, or switch that overlay to Key Vault-backed secret sync.

Current operator context already captured in repo:

1. AKS cluster name: `triad-azure-dev-aks`
2. AKS resource group: `triad-azure-dev-rg`
3. AKS cluster ID: `/subscriptions/73ecfaac-d482-41a4-89ca-94851eabac2c/resourceGroups/triad-azure-dev-rg/providers/Microsoft.ContainerService/managedClusters/triad-azure-dev-aks`
4. AKS ingress subnet ID: `/subscriptions/73ecfaac-d482-41a4-89ca-94851eabac2c/resourceGroups/triad-azure-dev-rg/providers/Microsoft.Network/virtualNetworks/triad-azure-dev-vnet/subnets/ingress-subnet`
5. AKS kubelet object ID: `81672f94-ae25-47a6-9a93-06d0470bf8c6`
6. AKS OIDC issuer: `https://eastus.oic.prod-aks.azure.com/8896947d-768a-47aa-a836-54e99ddf0975/ba855a3b-d736-4864-82fe-4ce58e9fc57b/`

## Step 6: Bootstrap ArgoCD On GKE

```bash
ROOT_APPS_FILE=/Users/lseino/triad-platform/triad-kubernetes-platform/platform/argocd/root-applications-gcp.yaml \
  /Users/lseino/triad-platform/triad-kubernetes-platform/scripts/bootstrap-argocd.sh
```

Follow-up edits before sync is expected to become healthy:

1. Replace GKE Workload Identity placeholders under `platform/external-dns-gcp/` and `platform/external-secrets-gcp/`.
2. Confirm Artifact Registry image paths in `workloads/pulsecart/gcp-dev/`.
3. Set the real Cloud SQL / Memorystore values and `DB_PASSWORD` secret in `workloads/pulsecart/gcp-dev/`, or switch that overlay to Secret Manager-backed secret sync.

Current operator context already captured in repo:

1. GKE cluster name: `triad-gcp-dev-gke`
2. GKE cluster ID: `projects/triad-platform-dev/locations/us-east1/clusters/triad-gcp-dev-gke`
3. GKE cluster endpoint: `35.229.104.164`
4. GKE region: `us-east1`
5. GKE workload identity pool: `triad-platform-dev.svc.id.goog`
6. VPC: `triad-gcp-dev-vpc`
7. Subnet: `triad-gke-dev-subnet`
8. Artifact Registry repo: `projects/triad-platform-dev/locations/us-east1/repositories/triad-app`

## Learning References

1. Foundation mapping:
   - `/Users/lseino/triad-platform/triad-landing-zones/docs/architecture/001-aws-azure-gcp-foundation-mapping.md`
2. Terraform backend parity:
   - `/Users/lseino/triad-platform/triad-landing-zones/docs/architecture/002-terraform-backend-parity-aws-azure-gcp.md`
3. Day-2 operations translation:
   - `/Users/lseino/triad-platform/triad-kubernetes-platform/docs/runbooks/multi-cloud-day2-translation-cheatsheet.md`
