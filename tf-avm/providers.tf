terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.29"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  required_version = "~> 1.9"
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}
