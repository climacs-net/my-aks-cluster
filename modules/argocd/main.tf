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

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = "cert-manager"
  chart      = "cert-manager"
  repository = "https://charts.jetstack.io"
  version    = "v1.7.1"

  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
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
    name  = "server.domain"
    value = "argocd.climacs.dev"
  }  
  
set {
    name  = "server.extraArgs"
    value = "{--insecure}"
  }

  set {
    name  = "server.ingress.enabled"
    value = "true"
  }

  set {
    name  = "server.ingress.hosts[0]"
    value = "argocd.climacs.dev"
  }

  set {
    name  = "server.ingress.tls[0].secretName"
    value = "argocd-tls-secret"
  }

  set {
    name  = "server.ingress.tls[0].hosts[0]"
    value = "argocd.climacs.dev"
  }

  set {
    name  = "server.ingress.annotations.kubernetes\\.io/ingress\\.class"
    value = "nginx"
  }

  set {
    name  = "server.ingress.annotations.cert-manager\\.io/issuer"
    value = "letsencrypt-prod"
  }
  

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
