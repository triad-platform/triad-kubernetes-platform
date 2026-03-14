resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.cluster_name}-dns"
  kubernetes_version  = var.kubernetes_version
  sku_tier            = "Standard"

  default_node_pool {
    name                        = "system"
    vm_size                     = var.node_vm_size
    vnet_subnet_id              = var.aks_subnet_id
    auto_scaling_enabled        = true
    min_count                   = var.node_min_count
    max_count                   = var.node_max_count
    temporary_name_for_rotation = "systemtmp"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    outbound_type  = "loadBalancer"
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  tags = var.tags
}
