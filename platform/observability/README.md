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
- Prometheus now includes a `configmap-reload` sidecar so ConfigMap-delivered scrape and alert rule changes automatically call `/-/reload` without manual operator intervention.
- Long retention and HA come later.

Current access pattern:
```bash
kubectl port-forward -n observability svc/grafana 3000:3000
kubectl port-forward -n observability svc/prometheus 9090:9090
kubectl port-forward -n observability svc/alertmanager 9093:9093
```

Prometheus rule troubleshooting sequence used during the March 14 AWS drill:
```bash
kubectl get configmap prometheus-rules -n observability -o yaml | rg 'PulseCartOrdersUnavailable|PulseCartGatewayUpstreamFailureRatio'
kubectl port-forward -n observability svc/prometheus 9090:9090
curl -s http://localhost:9090/api/v1/rules | rg 'PulseCartOrdersUnavailable|PulseCartGatewayUpstreamFailureRatio|state'
curl -s http://localhost:9090/api/v1/alerts | rg 'PulseCartOrdersUnavailable|PulseCartGatewayUpstreamFailureRatio|state|activeAt'
curl -sG http://localhost:9090/api/v1/query --data-urlencode 'query=up{job="orders"}'
curl -sG http://localhost:9090/api/v1/query --data-urlencode 'query=max_over_time(up{job="orders"}[2m])'
curl -X POST http://localhost:9090/-/reload
```

What those commands proved:

1. Argo had updated the live ConfigMap.
2. Prometheus had not reloaded the new rule file yet.
3. The `orders` outage signal was real in Prometheus query data.
4. Manual `/-/reload` made the new rules active immediately.
5. The permanent fix is the `configmap-reload` sidecar in the Prometheus deployment.

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
- The `ExternalSecret` resources use `creationPolicy: Owner`, so the synced Kubernetes secrets are now owned by `external-secrets` rather than Argo bootstrap manifests.

Preferred alert delivery path:
- Create an SNS topic in `triad-landing-zones`
- Subscribe your email to that topic
- Grant Alertmanager IRSA permission to publish to the topic
- Store the final Alertmanager config in Secrets Manager with `sns_configs`

Immediate next hardening steps:
1. Keep the AWS Secrets Manager values for `grafana-admin` and `alertmanager` as the source of truth and verify rotation still syncs cleanly.
2. Verify the Alertmanager SNS path continues to deliver and resolve alerts cleanly.
3. Increase retention and move from single-pod dev sizing to production-grade HA when this stack is promoted beyond dev.
