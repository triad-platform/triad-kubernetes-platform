# gcp-gke-dev Terraform

Terraform root stack for the first GKE dev cluster.
This root is composition-only and calls `modules/gcp/gke`.

## What This Stack Does

1. Creates a regional GKE cluster
2. Enables Workload Identity
3. Uses VPC-native IP allocation from landing-zone secondary ranges
4. Creates an autoscaled default node pool

## Inputs

This stack consumes values from `triad-landing-zones/gcp/envs/dev` outputs:

1. `project_id`
2. `region`
3. `vpc_name` (as `network_name`)
4. `gke_subnet_name` (as `subnetwork_name`)
5. `pods_secondary_range_name`
6. `services_secondary_range_name`

## First Safe Commands

```bash
cd /Users/lseino/triad-platform/triad-kubernetes-platform/clusters/gcp-gke-dev/terraform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
```

## Operator Notes

1. Run `gcloud auth application-default login` first.
2. Apply the GCP landing zone before this stack.
3. After apply, fetch kubeconfig with:
   - `gcloud container clusters get-credentials <cluster_name> --region <region> --project <project_id>`
4. Keep rollout and policy enforcement in GitOps, matching your AWS and Azure pattern.
