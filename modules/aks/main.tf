variable "resource_group_name" {}
variable "location" {}
variable "aks_cluster_name" {}
variable "kubernetes_version" {}
variable "client_id" {}
variable "client_secret" {}

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.aks_cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.aks_cluster_name

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  addon_profile {
    kube_dashboard {
      enabled = false
    }
  }

  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }

  tags = {
    Terraform = "true"
  }
}
