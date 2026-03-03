# scripts

Helper scripts for local dev, cluster bootstrap, validation, etc.

Available helpers:
- `eks-hop.sh <target-version>`
  - Performs a single EKS minor-version hop.
  - Skips the control plane or node group step if either is already at the target version.
  - Upgrades the managed add-ons (`vpc-cni`, `coredns`, `kube-proxy`, `aws-ebs-csi-driver`) to the first recommended version returned by AWS for that Kubernetes version.

Example:
```bash
/Users/lseino/triad-platform/triad-kubernetes-platform/scripts/eks-hop.sh 1.31
```

Environment overrides:
- `AWS_REGION`
- `EKS_CLUSTER_NAME`
- `EKS_NODEGROUP_NAME`
