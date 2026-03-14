# scripts

Helper scripts for local dev, cluster bootstrap, validation, etc.

Available helpers:
- `eks-hop.sh <target-version>`
  - Performs a single EKS minor-version hop.
  - Skips the control plane or node group step if either is already at the target version.
  - Upgrades the managed add-ons (`vpc-cni`, `coredns`, `kube-proxy`, `aws-ebs-csi-driver`) to the first recommended version returned by AWS for that Kubernetes version.
- `bootstrap-argocd.sh`
  - Installs/restores ArgoCD, waits for readiness, verifies `argocd-cm`, and applies root app-of-apps manifests.
  - Used by the AWS dev teardown/rebuild runbook as the default bootstrap path.
  - Also supports cluster-specific root app files through `ROOT_APPS_FILE`, for example:
    - AWS: `platform/argocd/root-applications.yaml`
    - Azure: `platform/argocd/root-applications-azure.yaml`
    - GCP: `platform/argocd/root-applications-gcp.yaml`

Example:
```bash
/Users/lseino/triad-platform/triad-kubernetes-platform/scripts/eks-hop.sh 1.35
/Users/lseino/triad-platform/triad-kubernetes-platform/scripts/bootstrap-argocd.sh
ROOT_APPS_FILE=/Users/lseino/triad-platform/triad-kubernetes-platform/platform/argocd/root-applications-azure.yaml \
  /Users/lseino/triad-platform/triad-kubernetes-platform/scripts/bootstrap-argocd.sh
```

Environment overrides:
- `AWS_REGION`
- `EKS_CLUSTER_NAME`
- `EKS_NODEGROUP_NAME`
- `ARGOCD_NAMESPACE`
- `ARGOCD_INSTALL_URL`
- `ROOT_APPS_FILE`
- `TIMEOUT_SECONDS`
