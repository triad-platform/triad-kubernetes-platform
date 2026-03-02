# Observability Baseline

This path is the first real in-cluster observability baseline managed by ArgoCD.

It deploys:
- Prometheus (single replica, dev-grade, emptyDir storage)
- Grafana (single replica, dev-grade, emptyDir storage)
- PulseCart starter alert rules
- PulseCart starter dashboard

Scope:
- This is intentionally minimal and optimized for reproducibility in the dev cluster.
- It is not a production monitoring stack yet.
- Persistent storage, auth hardening, long retention, and HA come later.

Current access pattern:
```bash
kubectl port-forward -n observability svc/grafana 3000:3000
kubectl port-forward -n observability svc/prometheus 9090:9090
```

Grafana defaults:
- user: `admin`
- password: `admin`

Immediate next hardening steps:
1. Change Grafana credentials away from defaults.
2. Move Prometheus and Grafana storage from `emptyDir` to persistent volumes.
3. Add Alertmanager once operator response workflows are ready.
