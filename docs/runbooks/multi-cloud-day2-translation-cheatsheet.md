# Multi-Cloud Day-2 Translation Cheat Sheet

This is the practical translation guide from AWS-first operations to Azure and GCP.

Focus areas:

1. DNS + ingress
2. identity federation (OIDC / workload identity)
3. storage classes and PV behavior
4. secret sync/injection patterns

## 1) DNS + Ingress

AWS baseline:

1. Ingress controller: AWS Load Balancer Controller
2. DNS automation: `external-dns` with Route 53
3. TLS: ACM certificate

Azure equivalent:

1. Ingress controller: NGINX or Application Gateway Ingress Controller
2. DNS automation: `external-dns` with Azure DNS
3. TLS: cert-manager with DNS challenge (or Azure-managed path)

GCP equivalent:

1. Ingress controller: GKE Ingress / Gateway API controller
2. DNS automation: `external-dns` with Cloud DNS
3. TLS: cert-manager with Cloud DNS challenge (or Google-managed cert path)

Operator checks:

1. verify DNS record exists for app host
2. verify ingress LB address/hostname is allocated
3. verify certificate reaches Ready state

## 2) Identity Federation (No Static Cloud Keys)

AWS baseline:

1. GitHub Actions OIDC role for CI push/signing access
2. IRSA for in-cluster service accounts

Azure equivalent:

1. GitHub OIDC federation to Entra ID app/service principal
2. AKS Workload Identity for in-cluster service accounts

GCP equivalent:

1. GitHub OIDC via Workload Identity Federation pool/provider
2. GKE Workload Identity for in-cluster service accounts

Operator checks:

1. CI can push to registry without static keys
2. in-cluster service account can access only required cloud resources
3. no long-lived cloud credentials are mounted in pods

## 3) Storage Classes and Persistent Volumes

AWS baseline:

1. EBS CSI driver
2. default `gp3`-backed storage class

Azure equivalent:

1. Azure Disk CSI driver
2. default managed-disk storage class

GCP equivalent:

1. GCE PD CSI driver
2. standard or balanced PD-backed storage class

Operator checks:

1. PVC moves to `Bound`
2. pod using PVC reaches Ready
3. volume reclaim policy matches dev intent

## 4) Secret Sync / Injection

AWS baseline:

1. External Secrets Operator reading AWS Secrets Manager

Azure equivalent:

1. External Secrets Operator with Key Vault provider, or
2. Secrets Store CSI Driver + Key Vault provider

GCP equivalent:

1. External Secrets Operator with Secret Manager provider, or
2. Secrets Store CSI Driver + GCP provider

Design guardrail:

1. keep app manifests cloud-agnostic
2. adapt only SecretStore/provider wiring per cloud
3. keep secret names and key contracts stable for workloads

## 5) App Delivery Pattern (Same Across Clouds)

Keep these constant:

1. same GitOps split (`apps/platform`, `apps/workloads`)
2. same policy baseline (Kyverno + admission rules)
3. same image-signing and attestation enforcement model
4. same SLO/observability/runbook posture

Change only:

1. cloud-specific controllers
2. cloud identity bindings
3. cloud DNS/certificate providers

## 6) Fast Troubleshooting Translation

If ingress is down:

1. AWS: ALB controller + Route 53 + ACM
2. Azure: ingress controller + Azure DNS + certificate source
3. GCP: ingress controller + Cloud DNS + certificate source

If secrets fail:

1. check provider CRDs
2. check workload identity binding
3. check cloud secret IAM permissions

If PVCs fail:

1. check CSI pods
2. check default StorageClass
3. check zone/region and node placement compatibility

## 7) What You Do On Your End During Bring-Up

1. Apply landing-zone Terraform first.
2. Copy landing-zone outputs into cluster Terraform tfvars.
3. Apply cluster Terraform.
4. Pull kubeconfig and verify cluster access.
5. Bootstrap GitOps apps.
6. Validate DNS, secret sync, storage, and admission policy tests.
