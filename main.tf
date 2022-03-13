terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.97.0"
    }
  }
  cloud {
    organization = "sama"

    workspaces {
      name = "Clouddev-vm"
    }
  }
}

provider "azurerm" {
  features {}
}