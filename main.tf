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

# Create a resource group
resource "azurerm_resource_group" "terraTest" {
  name     = "terraTest"
  location = "UK south"
}