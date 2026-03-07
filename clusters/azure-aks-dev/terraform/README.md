# azure-aks-dev Terraform

Terraform root stack for the first AKS dev cluster.
This root is composition-only and calls `modules/azure/aks`.

## What This Stack Does

1. Creates AKS in the landing-zone resource group
2. Enables OIDC issuer and Workload Identity
3. Creates an autoscaled default node pool
4. Grants `AcrPull` from AKS kubelet identity to the ACR

## Inputs

This stack consumes values from `triad-landing-zones/azure/envs/dev` outputs:

1. `subscription_id`
2. `tenant_id`
3. `resource_group_name`
4. `aks_subnet_id`
5. `ingress_subnet_id`
6. `container_registry_id` (as `acr_id`)

## First Safe Commands

```bash
cd /Users/lseino/triad-platform/triad-kubernetes-platform/clusters/azure-aks-dev/terraform
cp backend.hcl.example backend.hcl
cp terraform.tfvars.example terraform.tfvars
terraform init -backend-config=backend.hcl
terraform plan
```

## Operator Notes

1. Run `az login` first, then make sure your active subscription matches `subscription_id`.
2. Apply the Azure landing zone before this stack; this AKS root expects those IDs to already exist.
3. After apply, fetch kubeconfig with:
   - `az aks get-credentials --resource-group <resource_group_name> --name <cluster_name> --overwrite-existing`
4. Keep this stack focused on cluster and identity wiring; keep app/platform rollout in GitOps as done on AWS.
