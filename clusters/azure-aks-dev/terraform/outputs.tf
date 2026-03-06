output "cluster_name" {
  description = "AKS cluster name."
  value       = module.aks.cluster_name
}

output "resource_group_name" {
  description = "AKS resource group."
  value       = module.aks.resource_group_name
}

output "cluster_id" {
  description = "AKS cluster ID."
  value       = module.aks.cluster_id
}

output "oidc_issuer_url" {
  description = "AKS OIDC issuer URL for workload identity federation."
  value       = module.aks.oidc_issuer_url
}

output "kubelet_object_id" {
  description = "Kubelet managed identity object ID."
  value       = module.aks.kubelet_object_id
}

output "ingress_subnet_id" {
  description = "Ingress subnet ID carried forward for ingress controller setup."
  value       = var.ingress_subnet_id
}
