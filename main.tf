provider "azurerm" {
  features {}
}

locals {
  resource_group_name = "my-rg"
  location            = "East US"
  aks_cluster_name    = "my-aks-cluster"
  kubernetes_version  = "1.22.1"
  client_id           = "<your-client-id>"
  client_secret       = "<your-client-secret>"
}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = local.location
}

module "aks" {
  source              = "./modules/aks"
  resource_group_name = azurerm_resource_group.this.name
  location            = local.location
  aks_cluster_name    = local.aks_cluster_name
  kubernetes_version  = local.kubernetes_version
  client_id           = local.client_id
  client_secret       = local.client_secret
}

module "ingress" {
  source               = "./modules/ingress"
  cluster_resource_group = azurerm_resource_group.this.name
  aks_cluster_name     = local.aks_cluster_name
}

module "argocd" {
  source               = "./modules/argocd"
  cluster_resource_group = azurerm_resource_group.this.name
  aks_cluster_name     = local.aks_cluster_name
}
