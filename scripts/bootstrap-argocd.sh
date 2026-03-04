#!/usr/bin/env bash
set -euo pipefail

ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"
ARGOCD_INSTALL_URL="${ARGOCD_INSTALL_URL:-https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_APPS_FILE="${ROOT_APPS_FILE:-${SCRIPT_DIR}/../platform/argocd/root-applications.yaml}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-600}"
POLL_SECONDS="${POLL_SECONDS:-10}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1"
    exit 1
  fi
}

wait_for_pods_ready() {
  local namespace="$1"
  local timeout="$2"
  local poll="$3"
  local elapsed=0

  while true; do
    local total
    local ready

    total="$(kubectl get pods -n "${namespace}" --no-headers 2>/dev/null | wc -l | tr -d ' ')"
    ready="$(kubectl get pods -n "${namespace}" --no-headers 2>/dev/null | awk '{split($2,a,"/"); if (a[1]==a[2]) c++} END{print c+0}')"

    if [[ "${total}" -gt 0 && "${ready}" -eq "${total}" ]]; then
      echo "all pods ready in namespace ${namespace}: ${ready}/${total}"
      return 0
    fi

    if [[ "${elapsed}" -ge "${timeout}" ]]; then
      echo "timed out waiting for pods in ${namespace} to become ready"
      kubectl get pods -n "${namespace}" || true
      return 1
    fi

    echo "waiting for pods in ${namespace}: ready=${ready} total=${total} elapsed=${elapsed}s"
    sleep "${poll}"
    elapsed=$((elapsed + poll))
  done
}

require_cmd kubectl

if [[ ! -f "${ROOT_APPS_FILE}" ]]; then
  echo "root applications file not found: ${ROOT_APPS_FILE}"
  exit 1
fi

echo "using context: $(kubectl config current-context)"

echo "ensuring namespace ${ARGOCD_NAMESPACE} exists"
kubectl create namespace "${ARGOCD_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

echo "installing ArgoCD from ${ARGOCD_INSTALL_URL}"
kubectl apply -n "${ARGOCD_NAMESPACE}" --server-side --force-conflicts -f "${ARGOCD_INSTALL_URL}"

wait_for_pods_ready "${ARGOCD_NAMESPACE}" "${TIMEOUT_SECONDS}" "${POLL_SECONDS}"

echo "verifying argocd-cm exists"
kubectl get cm argocd-cm -n "${ARGOCD_NAMESPACE}"

echo "applying root applications from ${ROOT_APPS_FILE}"
kubectl apply -f "${ROOT_APPS_FILE}"

echo "current Argo applications"
kubectl get applications -n "${ARGOCD_NAMESPACE}" || true

echo "bootstrap complete"
