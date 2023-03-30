variable "cluster_resource_group" {}
variable "aks_cluster_name" {}

data "azurerm_kubernetes_cluster" "this" {
  name                = var.aks_cluster_name
  resource_group_name = var.cluster_resource_group
}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.this.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.this.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.this.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.this.kube_config.0.cluster_ca_certificate)
}

data "helm_repository" "argocd" {
  name = "argocd"
  url  = "https://argoproj.github.io/argo-helm"
}

resource "kubernetes_namespace" "argocd" {
metadata {
  name         = "argocd"
  }
}

resource "helm_release" "argocd" {
  name        = "argocd"
  namespace   = kubernetes_namespace.argocd.metadata[0].name
  repository  = data.helm_repository.argocd.metadata[0].name
  chart       = "argo-cd"

set {
  name        = "installCRDs"
  value       = "true"
}

set {
  name        = "server.service.type"
  value       = "LoadBalancer"
}

depends_on    = [kubernetes_namespace.argocd]
}
