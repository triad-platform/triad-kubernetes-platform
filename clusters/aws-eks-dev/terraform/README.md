# aws-eks-dev Terraform

Terraform root stack for the first Phase 2 EKS cluster.

## What This Stack Does

1. Creates the dev EKS cluster
2. Creates the default managed node group
3. Enables IRSA
4. Creates the IRSA role for the AWS Load Balancer Controller
5. Creates the IRSA role for external-dns
6. Creates the IRSA role for external-secrets
7. Enables the AWS EBS CSI managed add-on with an IRSA role for the CSI controller

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
6. You are ready to use the output `ebs_csi_role_arn` as part of the cluster storage baseline and managed add-on posture.
7. The external-secrets IAM policy should include the observability secret path if you want Grafana and Alertmanager config to come from Secrets Manager:
   - `triad/dev/observability/*`
8. Set `alertmanager_sns_topic_arns` when you want Alertmanager to publish directly to SNS through IRSA.
9. The EKS managed add-ons are configured with `most_recent = true` so Terraform follows the latest compatible AWS build for the declared cluster version instead of downgrading add-ons after manual or scripted version hops.

## Cost Baseline

The default node group is intentionally minimal for learning:

1. `t3.medium`
2. desired size `3`
3. min size `3`
4. max size `4`

This is now the practical floor for the current dev stack because:
1. core EKS system pods
2. ArgoCD
3. ALB controller
4. cert-manager
5. external-dns
6. external-secrets
7. NATS
8. PulseCart workloads
9. observability pods
all need headroom without hitting per-node pod limits.

If the cluster is already live and you hit scheduler events like `Too many pods`, update the real
`terraform.tfvars` to the same `3/3/4` values and apply. That is the current expected dev capacity.

## Upgrade Drift Notes

If you upgrade the control plane or add-ons outside Terraform (for example with `scripts/eks-hop.sh`), keep these aligned:

1. Set `kubernetes_version` in the real `terraform.tfvars` to the live cluster target.
2. Run `terraform plan` after the upgrade.
3. With `most_recent = true` on managed add-ons, Terraform should converge to the latest compatible build for that Kubernetes version instead of planning a downgrade to an older add-on build.
