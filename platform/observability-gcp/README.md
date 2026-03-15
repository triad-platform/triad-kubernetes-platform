# Observability Baseline

This path is the first real in-cluster observability baseline managed by ArgoCD.

It deploys:
- Alertmanager (single replica, dev-grade, PVC-backed)
- Prometheus (single replica, dev-grade, PVC-backed)
- Grafana (single replica, dev-grade, PVC-backed)
- PulseCart starter alert rules
- PulseCart starter dashboard

Scope:
- This is intentionally minimal and optimized for reproducibility in the dev cluster.
- It is not a production monitoring stack yet.
- Persistent storage is now enabled with dynamically provisioned PVCs.
- This now assumes the platform `gp3` CSI-backed `StorageClass` is present and the AWS EBS CSI add-on is enabled.
- Grafana admin credentials are now secret-backed through `external-secrets`.
- Alertmanager now uses a secret-backed config with an SNS receiver path sourced through `external-secrets`.
- `external-secrets` now owns those two secrets in the observability namespace, so Argo no longer competes with live secret data.
- Long retention and HA come later.

Current access pattern:
```bash
kubectl port-forward -n observability svc/grafana 3000:3000
kubectl port-forward -n observability svc/prometheus 9090:9090
kubectl port-forward -n observability svc/alertmanager 9093:9093
```

Grafana access:
- secret: `grafana-admin`
- user key: `admin-user`
- password key: `admin-password`
- live source of truth: cloud secret provider via `ExternalSecret`
- the checked-in `grafana-admin-secret.yaml` file is reference-only and is not applied by this kustomization

Secret source of truth:
- `SecretStore`: `observability-aws-secrets`
- AWS secret name for Grafana: `triad/dev/observability/grafana-admin`
  - expected JSON keys: `admin_user`, `admin_password`
- AWS secret name for Alertmanager: `triad/dev/observability/alertmanager`
  - expected JSON key: `config`
- The `ExternalSecret` resources use `creationPolicy: Owner`, so the synced Kubernetes secrets are owned by `external-secrets` rather than Argo bootstrap manifests.
- The checked-in placeholder secret manifests remain only as local reference material for first-pass authoring.

Preferred alert delivery path:
- Create an SNS topic in `triad-landing-zones`
- Subscribe your email to that topic
- Grant Alertmanager IRSA permission to publish to the topic
- Store the final Alertmanager config in Secrets Manager with `sns_configs`

Immediate next hardening steps:
1. Keep the AWS Secrets Manager values for `grafana-admin` and `alertmanager` as the source of truth and verify rotation still syncs cleanly.
2. Verify the Alertmanager SNS path continues to deliver and resolve alerts cleanly.
3. Increase retention and move from single-pod dev sizing to production-grade HA when this stack is promoted beyond dev.
