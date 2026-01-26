# Packer template for AVD Management Image
# This creates a custom Windows 11 image with office and management tools

packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 2"
    }
    windows-update = {
      source  = "github.com/rgl/windows-update"
      version = "~> 0.14"
    }
  }
}

# Variables
variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant ID"
}

variable "client_id" {
  type        = string
  description = "Azure client ID"
}

variable "client_secret" {
  type        = string
  description = "Azure client secret"
  sensitive   = true
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for image building"
  default     = "rg-avd-images"
}

variable "location" {
  type        = string
  description = "Azure location"
  default     = "West Europe"
}

variable "image_version" {
  type        = string
  description = "Version of the image"
  default     = "1.0.0"
}

variable "shared_image_gallery_name" {
  type        = string
  description = "Name of the Shared Image Gallery"
}

# Source configuration
source "azure-arm" "mgmt_image" {
  # Authentication
  subscription_id = var.subscription_id
  tenant_id      = var.tenant_id
  client_id      = var.client_id
  client_secret  = var.client_secret

  # Resource configuration
  managed_image_resource_group_name = var.resource_group_name
  location                         = var.location

  # Base image
  os_type         = "Windows"
  image_publisher = "MicrosoftWindowsDesktop"
  image_offer     = "Windows-11"
  image_sku       = "win11-22h2-avd"
  image_version   = "latest"

  # VM configuration
  vm_size = "Standard_D2s_v3"

  # Shared Image Gallery configuration
  shared_image_gallery_destination {
    subscription         = var.subscription_id
    resource_group       = var.resource_group_name
    gallery_name        = var.shared_image_gallery_name
    image_name          = "avd-mgmt-image"
    image_version       = var.image_version
    replication_regions = ["West Europe", "East US"]
    storage_account_type = "Standard_LRS"
  }

  # Build configuration
  communicator   = "winrm"
  winrm_use_ssl  = true
  winrm_insecure = true
  winrm_timeout  = "5m"
  winrm_username = "packer"
}

# Build configuration
build {
  name = "mgmt-image"
  sources = [
    "source.azure-arm.mgmt_image"
  ]

  # Install Windows Updates
  provisioner "windows-update" {
    search_criteria = "IsInstalled=0"
    filters = [
      "exclude:$_.Title -like '*Preview*'",
      "include:$true"
    ]
    update_limit = 25
  }

  # Install Chocolatey
  provisioner "powershell" {
    inline = [
      "Set-ExecutionPolicy Bypass -Scope Process -Force",
      "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072",
      "iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    ]
  }

  # Install management and office tools
  provisioner "powershell" {
    inline = [
      "choco install -y googlechrome",
      "choco install -y firefox",
      "choco install -y microsoft-edge",
      "choco install -y adobereader",
      "choco install -y 7zip",
      "choco install -y notepadplusplus",
      "choco install -y slack",
      "choco install -y teams",
      "choco install -y zoom",
      "choco install -y skype",
      "choco install -y vlc",
      "choco install -y paint.net",
      "choco install -y greenshot",
      "choco install -y putty",
      "choco install -y winscp",
      "choco install -y filezilla"
    ]
  }

  # Install Office 365
  provisioner "powershell" {
    script = "./scripts/install-office365.ps1"
  }

  # Install Microsoft Loop (if available)
  provisioner "powershell" {
    inline = [
      "Write-Host 'Installing Microsoft Loop...'",
      "# Microsoft Loop installation via Microsoft Store or direct download",
      "# This would be replaced with actual installation commands",
      "Write-Host 'Microsoft Loop installation placeholder completed'"
    ]
  }

  # Install Confluence Desktop (if available)
  provisioner "powershell" {
    inline = [
      "Write-Host 'Installing Confluence Desktop tools...'",
      "# Install Confluence-related browser extensions and tools",
      "Write-Host 'Confluence tools installation placeholder completed'"
    ]
  }

  # Configure browsers with business extensions
  provisioner "powershell" {
    script = "./scripts/configure-browsers.ps1"
  }

  # Install business intelligence tools
  provisioner "powershell" {
    inline = [
      "choco install -y powerbi",
      "choco install -y tableau-desktop",
      "# Add other BI tools as needed"
    ]
  }

  # Configure system for business users
  provisioner "powershell" {
    script = "./scripts/configure-business-system.ps1"
  }

  # Security hardening for management users
  provisioner "powershell" {
    script = "./scripts/security-hardening-mgmt.ps1"
  }

  # Final cleanup and optimization
  provisioner "powershell" {
    script = "./scripts/cleanup-and-optimize.ps1"
  }

  # Restart before sysprep
  provisioner "windows-restart" {
    restart_timeout = "10m"
  }

  # Final Windows Updates check
  provisioner "windows-update" {
    search_criteria = "IsInstalled=0"
    filters = [
      "exclude:$_.Title -like '*Preview*'",
      "include:$true"
    ]
    update_limit = 10
  }

  # Sysprep
  provisioner "powershell" {
    inline = [
      "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit /mode:vm",
      "while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10  } else { break } }"
    ]
  }
}