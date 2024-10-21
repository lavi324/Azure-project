provider "azurerm" {
  features {}
  subscription_id = "a3b3082d-db04-406b-aceb-26186cf2afd0"  # Your Azure Subscription ID
}

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"  # Specify the desired version
    }
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "my-resource-group"
  location = "Wast US"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "my-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "my-subnet"  # Ensure this is closed properly
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}  # Ensure this closing brace is here

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "my-aks-cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "myaks"

  default_node_pool {
    name                          = "default"
    node_count                    = 1
    vm_size                       = "Standard_DS2_v2"
    temporary_name_for_rotation   = "temp"  # Ensure this is a valid name
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "Terraform"
  }
}  # Ensure this closing brace is here

resource "null_resource" "wait_for_aks" {
  depends_on = [azurerm_kubernetes_cluster.aks_cluster]

  provisioner "local-exec" {
    command = <<EOT
      sleep 120
      az aks get-credentials --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_kubernetes_cluster.aks_cluster.name}
    EOT
  }
}  # Ensure this closing brace is here

resource "helm_release" "jenkins" {
  depends_on = [azurerm_kubernetes_cluster.aks_cluster]
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = "5.3.1"
  namespace  = "jenkins"
  wait       = true
}  # Ensure this closing brace is here

resource "helm_release" "argo_cd" {
  depends_on = [azurerm_kubernetes_cluster.aks_cluster]
  name       = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.3.0"
  namespace  = "argo"
  wait       = true
}  # Ensure this closing brace is here
