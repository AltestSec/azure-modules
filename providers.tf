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
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    virtual_machine {
      delete_os_disk_on_deletion = true
    }
  }

  # Use environment variables for authentication (ARM_CLIENT_ID, ARM_CLIENT_SECRET, etc.)
  # These will be set by the GitHub Actions workflow
}