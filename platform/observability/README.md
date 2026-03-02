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
- This still assumes a working default storage class in the cluster.
- Auth hardening, long retention, and HA come later.

Current access pattern:
```bash
kubectl port-forward -n observability svc/grafana 3000:3000
kubectl port-forward -n observability svc/prometheus 9090:9090
kubectl port-forward -n observability svc/alertmanager 9093:9093
```

Grafana defaults:
- user: `admin`
- password: `admin`

Immediate next hardening steps:
1. Change Grafana credentials away from defaults.
2. Add a real notification receiver (Slack/email/PagerDuty) to Alertmanager.
3. Increase retention and move from single-pod dev sizing to production-grade HA when this stack is promoted beyond dev.
