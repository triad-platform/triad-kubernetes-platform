# aws-eks-dev

This folder represents the first dev cluster contract for Phase 2.

## Purpose

It captures the exact inputs the EKS bootstrap layer expects from `triad-landing-zones` before the full cluster implementation is written.

## File

1. `cluster-contract.yaml`
   - placeholder mapping of landing-zone outputs into EKS/bootstrap inputs

## Why This Exists

This keeps the repo boundary explicit:

1. `triad-landing-zones` owns AWS network outputs
2. `triad-kubernetes-platform` owns cluster consumption and GitOps bootstrap
3. `triad-app` owns runtime expectations for workloads
