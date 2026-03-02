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
- Grafana admin credentials are now secret-backed and should be rotated from the placeholder value immediately.
- Alertmanager now uses a secret-backed config with a webhook receiver placeholder that should be replaced with a real destination.
- `external-secrets` now also watches the observability namespace and can merge AWS Secrets Manager values into those two secrets without a hard cutover.
- Long retention and HA come later.

Current access pattern:
```bash
kubectl port-forward -n observability svc/grafana 3000:3000
kubectl port-forward -n observability svc/prometheus 9090:9090
kubectl port-forward -n observability svc/alertmanager 9093:9093
```

Grafana bootstrap credentials:
- secret: `grafana-admin`
- user key: `admin-user`
- password key: `admin-password`
- current placeholder password: `CHANGE-ME-OBSERVABILITY-ADMIN`

External-secrets migration path:
- `SecretStore`: `observability-aws-secrets`
- AWS secret name for Grafana: `triad/dev/observability/grafana-admin`
  - expected JSON keys: `admin_user`, `admin_password`
- AWS secret name for Alertmanager: `triad/dev/observability/alertmanager`
  - expected JSON key: `config`
- The `ExternalSecret` resources use `creationPolicy: Merge`, so the existing bootstrap secrets remain valid until AWS-backed values are available.

Immediate next hardening steps:
1. Replace the Grafana placeholder password in the `grafana-admin` secret with a real value.
2. Replace the Alertmanager webhook placeholder in the `alertmanager-config` secret with a real Slack/email/PagerDuty-capable destination.
3. Increase retention and move from single-pod dev sizing to production-grade HA when this stack is promoted beyond dev.
