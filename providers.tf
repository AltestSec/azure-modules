terraform {
  required_version = ">=1.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatestorage"
    container_name      = "tfstate"
    key                 = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    virtual_machine {
      delete_os_disk_on_deletion = true
    }
  }

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}