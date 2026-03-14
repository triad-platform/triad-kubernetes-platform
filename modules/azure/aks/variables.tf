variable "cluster_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "aks_subnet_id" {
  type = string
}

variable "node_vm_size" {
  type = string
}

variable "node_min_count" {
  type = number
}

variable "node_max_count" {
  type = number
}

variable "tags" {
  type    = map(string)
  default = {}
}
