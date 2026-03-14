# AWS Hardening Next Sprint

This runbook is the active execution path after validating Azure and GCP cluster lifecycle operations.

The goal is not to expand cloud surface area further right now. The goal is to make the AWS reference path cleaner, harder to break, and easier to defend before the next AKS/GKE parity pass.

## Outcomes

1. The EKS path remains the reference deployment model.
2. Phase 3 supply-chain enforcement is easier to explain and verify.
3. Phase 4 reliability artifacts better match the live dev platform.
4. Rebuild, recovery, and promotion steps depend less on tribal knowledge.

## Workstream 1: Supply Chain Tightening

1. Verify the image promotion flow in `triad-app` still matches the registries and patterns enforced by `triad-ci-security/policy/admission/`.
2. Remove stale placeholders or contradictory examples where the real AWS account, region, ECR, and IRSA assumptions are already known.
3. Re-run signed-image and approved-registry deny/allow validation against the live EKS cluster.
4. Capture fresh evidence for build, SBOM, scan, sign, attest, and admission outcomes.

## Workstream 2: Runtime Secret And Config Cleanup

1. Reduce plaintext or repo-pinned secret examples where the real path is now `external-secrets` plus AWS-managed secret sources.
2. Make sure app, observability, and platform overlays describe the same secret-management boundary.
3. Keep dev bootstrap practical, but stop normalizing placeholder values that hide real operator dependencies.

## Workstream 3: Reliability Hardening

1. Reconcile alert rules, dashboard expectations, and runbooks with the current AWS observability stack.
2. Re-run at least one failure drill that exercises async order flow visibility and documented recovery.
3. Tighten teardown/rebuild guidance where stale-lock, CRD ordering, or Argo root sync issues were previously observed.

## Workstream 4: Evidence And Narrative

1. Update workspace and repo READMEs when the AWS hardening state changes.
2. Add or refresh at least one `triad-portfolio` memo or drill artifact with concrete findings.
3. Record what must remain AWS-specific versus what is ready to port back to AKS and GKE.

## Exit Signal

This sprint is complete when all of the following are true:

1. The EKS dev path can be rebuilt and validated without undocumented recovery steps.
2. Admission enforcement and image trust evidence is current and reproducible.
3. Runbooks match the live platform behavior closely enough to survive a fresh teardown/rebuild cycle.
4. The next AKS/GKE rollout attempt would reuse a cleaner AWS baseline rather than re-learning the same gaps.
