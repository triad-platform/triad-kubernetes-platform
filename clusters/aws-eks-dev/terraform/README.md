# aws-eks-dev Terraform

Terraform root stack for the first Phase 2 EKS cluster.

## What This Stack Does

1. Creates the dev EKS cluster
2. Creates the default managed node group
3. Enables IRSA
4. Creates the IRSA role for the AWS Load Balancer Controller
5. Creates the IRSA role for external-dns
6. Creates the IRSA role for external-secrets

## Inputs

This stack consumes the current dev outputs from `triad-landing-zones`:

1. `vpc_id`
2. `eks_cluster_subnet_ids`
3. `ingress_public_subnet_ids`

The current example values already match the active dev landing zone.

Ownership model:

1. `triad-landing-zones` owns subnet creation
2. `triad-landing-zones` also owns the Kubernetes discovery tags required on those shared subnets
3. this EKS stack consumes already cluster-ready subnet IDs

That split is intentional so the cluster stack does not mutate foundational network resources.

## Remote State

Use the same remote backend baseline created in `triad-landing-zones`:

1. S3 bucket for state
2. DynamoDB table for locking

## First Safe Commands

```bash
cd /Users/lseino/triad-platform/triad-kubernetes-platform/clusters/aws-eks-dev/terraform
cp backend.hcl.example backend.hcl
cp terraform.tfvars.example terraform.tfvars
terraform init -backend-config=backend.hcl
terraform plan
```

## Do Not Apply Until

1. You are ready to incur EKS cost
2. The Route 53 / ACM path for `pulsecart-dev.cloudevopsguru.com` is defined
3. You are ready to use the output `aws_load_balancer_controller_role_arn` to keep the manifest aligned:
   - `/Users/lseino/triad-platform/triad-kubernetes-platform/platform/ingress/serviceaccount.yaml`
4. You are ready to use the output `external_dns_role_arn` to keep the manifest aligned:
   - `/Users/lseino/triad-platform/triad-kubernetes-platform/platform/external-dns/serviceaccount.yaml`
5. You are ready to use the output `external_secrets_role_arn` to keep the manifest aligned:
   - `/Users/lseino/triad-platform/triad-kubernetes-platform/platform/external-secrets/serviceaccount.yaml`

## Cost Baseline

The default node group is intentionally minimal for learning:

1. `t3.medium`
2. desired size `1`
3. min size `1`
4. max size `2`
