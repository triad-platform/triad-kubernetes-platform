module "aks" {
  source = "../../../modules/azure/aks"

  cluster_name        = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  kubernetes_version  = var.kubernetes_version
  aks_subnet_id       = var.aks_subnet_id
  node_vm_size        = var.node_vm_size
  node_min_count      = var.node_min_count
  node_max_count      = var.node_max_count
  tags                = var.tags
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_object_id
}
