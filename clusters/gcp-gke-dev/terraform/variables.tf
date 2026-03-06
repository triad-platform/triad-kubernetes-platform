variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "GCP region for GKE."
  type        = string
  default     = "us-east1"
}

variable "cluster_name" {
  description = "GKE cluster name."
  type        = string
  default     = "triad-gcp-dev-gke"
}

variable "kubernetes_version" {
  description = "GKE Kubernetes version."
  type        = string
  default     = "1.31"
}

variable "network_name" {
  description = "VPC network name from landing zone."
  type        = string
}

variable "subnetwork_name" {
  description = "Subnetwork name from landing zone."
  type        = string
}

variable "pods_secondary_range_name" {
  description = "Secondary range name for pods."
  type        = string
  default     = "pods"
}

variable "services_secondary_range_name" {
  description = "Secondary range name for services."
  type        = string
  default     = "services"
}

variable "node_machine_type" {
  description = "GKE node machine type."
  type        = string
  default     = "e2-standard-4"
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

variable "labels" {
  description = "Labels for GKE resources."
  type        = map(string)
  default = {
    environment = "dev"
    stage       = "phase5"
    managed_by  = "terraform"
  }
}
