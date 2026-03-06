module "gke" {
  source = "../../../modules/gcp/gke"

  project_id                    = var.project_id
  region                        = var.region
  cluster_name                  = var.cluster_name
  kubernetes_version            = var.kubernetes_version
  network_name                  = var.network_name
  subnetwork_name               = var.subnetwork_name
  pods_secondary_range_name     = var.pods_secondary_range_name
  services_secondary_range_name = var.services_secondary_range_name
  node_machine_type             = var.node_machine_type
  node_min_count                = var.node_min_count
  node_max_count                = var.node_max_count
  labels                        = var.labels
}
