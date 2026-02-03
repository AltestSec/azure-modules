terraform {
  required_version = ">=1.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }

  # Backend configuration will be provided via terraform init -backend-config
  # This allows dynamic backend configuration based on workflow inputs
  # CONSOLIDATED BACKEND: All components share ONE backend storage setup
  backend "azurerm" {
    # Configuration provided via init command:
    # resource_group_name  = "{prefix}-tfstate-rg"           (SHARED)
    # storage_account_name = "{prefix}tfstatestorage"        (SHARED)  
    # container_name       = "tfstate-{environment}"         (SHARED)
    # key                  = "{component}.tfstate"           (COMPONENT-SPECIFIC)
    # use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {
    virtual_machine {
      delete_os_disk_on_deletion = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }

  # Use environment variables for authentication (ARM_CLIENT_ID, ARM_CLIENT_SECRET, etc.)
  # These will be set by the GitHub Actions workflow
}