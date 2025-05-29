terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

# Get own public IP to add into storage account network rules so that modifications can be made from terraform via external calls
# data "http" "my_ip" {
# url = "https://ipv4.icanhazip.com"
# }