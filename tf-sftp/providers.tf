terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "2.4.0"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

data "azurerm_client_config" "current" {}

# Get own public IP to add into storage account network rules so that modifications can be made from terraform via external calls
data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com"
}


