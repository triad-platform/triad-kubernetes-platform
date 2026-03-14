output "cluster_name" {
  description = "GKE cluster name."
  value       = module.gke.cluster_name
}

output "cluster_id" {
  description = "GKE cluster ID."
  value       = module.gke.cluster_id
}

output "cluster_endpoint" {
  description = "GKE control plane endpoint."
  value       = module.gke.cluster_endpoint
}

output "workload_identity_pool" {
  description = "GKE workload identity pool."
  value       = module.gke.workload_identity_pool
}
