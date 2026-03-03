#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
CLUSTER="${EKS_CLUSTER_NAME:-triad-aws-eks-dev}"
NODEGROUP="${EKS_NODEGROUP_NAME:-default-20260228232254827600000012}"
TARGET_VERSION="${1:-}"

if [[ -z "${TARGET_VERSION}" ]]; then
  echo "usage: $(basename "$0") <target-kubernetes-version>"
  exit 1
fi

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1"
    exit 1
  fi
}

describe_cluster_version() {
  aws eks describe-cluster \
    --region "${REGION}" \
    --name "${CLUSTER}" \
    --query 'cluster.version' \
    --output text
}

describe_cluster_status() {
  aws eks describe-cluster \
    --region "${REGION}" \
    --name "${CLUSTER}" \
    --query 'cluster.status' \
    --output text
}

describe_nodegroup_version() {
  aws eks describe-nodegroup \
    --region "${REGION}" \
    --cluster-name "${CLUSTER}" \
    --nodegroup-name "${NODEGROUP}" \
    --query 'nodegroup.version' \
    --output text
}

describe_nodegroup_status() {
  aws eks describe-nodegroup \
    --region "${REGION}" \
    --cluster-name "${CLUSTER}" \
    --nodegroup-name "${NODEGROUP}" \
    --query 'nodegroup.status' \
    --output text
}

wait_for_cluster_active() {
  while true; do
    local status
    status="$(describe_cluster_status)"
    local version
    version="$(describe_cluster_version)"
    echo "cluster status=${status} version=${version}"
    [[ "${status}" == "ACTIVE" ]] && break
    sleep 20
  done
}

wait_for_cluster_update() {
  local update_id="$1"
  while true; do
    local update_status
    update_status="$(
      aws eks describe-update \
        --region "${REGION}" \
        --name "${CLUSTER}" \
        --update-id "${update_id}" \
        --query 'update.status' \
        --output text
    )"
    local cluster_status
    cluster_status="$(describe_cluster_status)"
    local cluster_version
    cluster_version="$(describe_cluster_version)"
    echo "control plane update status=${update_status} cluster_status=${cluster_status} version=${cluster_version}"
    [[ "${update_status}" == "Successful" && "${cluster_version}" == "${TARGET_VERSION}" ]] && break
    if [[ "${update_status}" == "Failed" || "${update_status}" == "Cancelled" ]]; then
      echo "control plane upgrade failed"
      exit 1
    fi
    sleep 20
  done
}

wait_for_nodegroup_active() {
  while true; do
    local status
    status="$(describe_nodegroup_status)"
    local version
    version="$(describe_nodegroup_version)"
    echo "nodegroup status=${status} version=${version}"
    [[ "${status}" == "ACTIVE" ]] && break
    sleep 20
  done
}

upgrade_control_plane_if_needed() {
  local current_version
  current_version="$(describe_cluster_version)"
  echo "current control plane version=${current_version}"

  if [[ "${current_version}" == "${TARGET_VERSION}" ]]; then
    echo "control plane already at ${TARGET_VERSION}; skipping"
    return
  fi

  echo "upgrading control plane to ${TARGET_VERSION}"
  local update_id
  update_id="$(
    aws eks update-cluster-version \
      --region "${REGION}" \
      --name "${CLUSTER}" \
      --kubernetes-version "${TARGET_VERSION}" \
      --query 'update.id' \
      --output text
  )"
  echo "control plane update id=${update_id}"
  wait_for_cluster_update "${update_id}"
  wait_for_cluster_active
}

addon_target_version() {
  local addon_name="$1"
  aws eks describe-addon-versions \
    --region "${REGION}" \
    --kubernetes-version "${TARGET_VERSION}" \
    --addon-name "${addon_name}" \
    --query 'addons[0].addonVersions[0].addonVersion' \
    --output text
}

describe_addon_version() {
  local addon_name="$1"
  aws eks describe-addon \
    --region "${REGION}" \
    --cluster-name "${CLUSTER}" \
    --addon-name "${addon_name}" \
    --query 'addon.addonVersion' \
    --output text
}

describe_addon_status() {
  local addon_name="$1"
  aws eks describe-addon \
    --region "${REGION}" \
    --cluster-name "${CLUSTER}" \
    --addon-name "${addon_name}" \
    --query 'addon.status' \
    --output text
}

wait_for_addon_active() {
  local addon_name="$1"
  while true; do
    local status
    status="$(describe_addon_status "${addon_name}")"
    local version
    version="$(describe_addon_version "${addon_name}")"
    echo "addon ${addon_name} status=${status} version=${version}"
    [[ "${status}" == "ACTIVE" ]] && break
    if [[ "${status}" == "DEGRADED" || "${status}" == "CREATE_FAILED" || "${status}" == "DELETE_FAILED" || "${status}" == "UPDATE_FAILED" ]]; then
      echo "addon ${addon_name} is in a failed state: ${status}"
      exit 1
    fi
    sleep 15
  done
}

upgrade_addon_if_needed() {
  local addon_name="$1"
  local desired_addon_version
  desired_addon_version="$(addon_target_version "${addon_name}")"

  if [[ -z "${desired_addon_version}" || "${desired_addon_version}" == "None" ]]; then
    echo "no recommended version found for addon ${addon_name} on ${TARGET_VERSION}; skipping"
    return
  fi

  local current_addon_version
  current_addon_version="$(describe_addon_version "${addon_name}")"
  local current_addon_status
  current_addon_status="$(describe_addon_status "${addon_name}")"

  echo "addon ${addon_name} status=${current_addon_status} current=${current_addon_version} target=${desired_addon_version}"

  if [[ "${current_addon_status}" == "UPDATING" || "${current_addon_status}" == "CREATING" || "${current_addon_status}" == "DELETING" ]]; then
    echo "addon ${addon_name} is already ${current_addon_status}; waiting for it to become ACTIVE"
    wait_for_addon_active "${addon_name}"
    current_addon_version="$(describe_addon_version "${addon_name}")"
    echo "addon ${addon_name} post-wait current=${current_addon_version} target=${desired_addon_version}"
  fi

  if [[ "${current_addon_version}" == "${desired_addon_version}" ]]; then
    echo "addon ${addon_name} already at target; skipping"
    return
  fi

  local update_id
  update_id="$(
    aws eks update-addon \
      --region "${REGION}" \
      --cluster-name "${CLUSTER}" \
      --addon-name "${addon_name}" \
      --addon-version "${desired_addon_version}" \
      --resolve-conflicts OVERWRITE \
      --query 'update.id' \
      --output text
  )"
  echo "addon ${addon_name} update id=${update_id}"

  while true; do
    local status
    status="$(
      aws eks describe-update \
        --region "${REGION}" \
        --name "${CLUSTER}" \
        --addon-name "${addon_name}" \
        --update-id "${update_id}" \
        --query 'update.status' \
        --output text
    )"
    echo "addon ${addon_name} update status=${status}"
    [[ "${status}" == "Successful" ]] && break
    if [[ "${status}" == "Failed" || "${status}" == "Cancelled" ]]; then
      echo "addon ${addon_name} upgrade failed"
      exit 1
    fi
    sleep 15
  done

  wait_for_addon_active "${addon_name}"
}

upgrade_nodegroup_if_needed() {
  local current_version
  current_version="$(describe_nodegroup_version)"
  echo "current nodegroup version=${current_version}"

  if [[ "${current_version}" == "${TARGET_VERSION}" ]]; then
    echo "nodegroup already at ${TARGET_VERSION}; skipping"
    return
  fi

  echo "upgrading nodegroup to ${TARGET_VERSION}"
  local update_id
  update_id="$(
    aws eks update-nodegroup-version \
      --region "${REGION}" \
      --cluster-name "${CLUSTER}" \
      --nodegroup-name "${NODEGROUP}" \
      --kubernetes-version "${TARGET_VERSION}" \
      --query 'update.id' \
      --output text
  )"
  echo "nodegroup update id=${update_id}"

  while true; do
    local status
    status="$(
      aws eks describe-update \
        --region "${REGION}" \
        --name "${CLUSTER}" \
        --nodegroup-name "${NODEGROUP}" \
        --update-id "${update_id}" \
        --query 'update.status' \
        --output text
    )"
    echo "nodegroup update status=${status}"
    [[ "${status}" == "Successful" ]] && break
    if [[ "${status}" == "Failed" || "${status}" == "Cancelled" ]]; then
      echo "nodegroup upgrade failed"
      exit 1
    fi
    sleep 20
  done

  wait_for_nodegroup_active
}

main() {
  require_cmd aws

  echo "cluster=${CLUSTER} nodegroup=${NODEGROUP} region=${REGION} target=${TARGET_VERSION}"
  echo "== precheck"
  aws eks describe-cluster \
    --region "${REGION}" \
    --name "${CLUSTER}" \
    --query 'cluster.{version:version,status:status}' \
    --output json
  aws eks describe-nodegroup \
    --region "${REGION}" \
    --cluster-name "${CLUSTER}" \
    --nodegroup-name "${NODEGROUP}" \
    --query 'nodegroup.{version:version,status:status,scaling:scalingConfig}' \
    --output json

  upgrade_control_plane_if_needed

  for addon in vpc-cni coredns kube-proxy aws-ebs-csi-driver; do
    upgrade_addon_if_needed "${addon}"
  done

  upgrade_nodegroup_if_needed

  echo "== final state"
  aws eks describe-cluster \
    --region "${REGION}" \
    --name "${CLUSTER}" \
    --query 'cluster.{version:version,status:status}' \
    --output json
  aws eks describe-nodegroup \
    --region "${REGION}" \
    --cluster-name "${CLUSTER}" \
    --nodegroup-name "${NODEGROUP}" \
    --query 'nodegroup.{version:version,status:status,scaling:scalingConfig}' \
    --output json
}

main "$@"
