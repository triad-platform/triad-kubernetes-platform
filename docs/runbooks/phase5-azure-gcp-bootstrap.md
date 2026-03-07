# Phase 5 Azure + GCP Bootstrap

This runbook is the operator path to stand up Azure and GCP baselines after AWS is green.

## Scope

1. Apply Azure landing zone
2. Apply AKS cluster
3. Apply GCP landing zone
4. Apply GKE cluster
5. Confirm kubeconfig access for both clusters

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
3. You are ready to apply the same GitOps app-of-apps pattern next

## Learning References

1. Foundation mapping:
   - `/Users/lseino/triad-platform/triad-landing-zones/docs/architecture/001-aws-azure-gcp-foundation-mapping.md`
2. Day-2 operations translation:
   - `/Users/lseino/triad-platform/triad-kubernetes-platform/docs/runbooks/multi-cloud-day2-translation-cheatsheet.md`
