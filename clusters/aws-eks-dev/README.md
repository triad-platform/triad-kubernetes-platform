# aws-eks-dev

This folder represents the first dev cluster contract for Phase 2.

## Purpose

It captures the exact inputs the EKS bootstrap layer expects from `triad-landing-zones` before the full cluster implementation is written.

## File

1. `cluster-contract.yaml`
   - current mapping of landing-zone outputs into EKS/bootstrap inputs
2. `terraform/`
   - first real EKS Terraform root for the dev cluster

## Why This Exists

This keeps the repo boundary explicit:

1. `triad-landing-zones` owns AWS network outputs
2. `triad-kubernetes-platform` owns cluster consumption and GitOps bootstrap
3. `triad-app` owns runtime expectations for workloads

## Current Implementation Status

This folder now includes:

1. a real Terraform root for EKS
2. the IRSA role contract for the AWS Load Balancer Controller

It is ready for `terraform init` and `terraform plan`, but should not be applied until you are ready to create the EKS cluster.
