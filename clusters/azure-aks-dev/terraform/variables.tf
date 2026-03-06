variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID."
  type        = string
}

variable "location" {
  description = "Azure region for AKS."
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Landing-zone resource group name to place AKS resources."
  type        = string
}

variable "cluster_name" {
  description = "AKS cluster name."
  type        = string
  default     = "triad-azure-dev-aks"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version."
  type        = string
  default     = "1.31"
}

variable "aks_subnet_id" {
  description = "Subnet ID for AKS node pool."
  type        = string
}

variable "ingress_subnet_id" {
  description = "Subnet ID reserved for ingress components."
  type        = string
}

variable "acr_id" {
  description = "ACR ID to attach AcrPull permissions to the kubelet identity."
  type        = string
}

variable "node_vm_size" {
  description = "AKS node VM size."
  type        = string
  default     = "Standard_D4s_v5"
}

variable "node_min_count" {
  description = "Minimum autoscaled node count."
  type        = number
  default     = 3
}

variable "node_max_count" {
  description = "Maximum autoscaled node count."
  type        = number
  default     = 4
}

variable "tags" {
  description = "Tags for AKS resources."
  type        = map(string)
  default = {
    CostCenter = "learning"
    Stage      = "phase5"
    ManagedBy  = "terraform"
  }
}
