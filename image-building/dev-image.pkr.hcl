# Packer template for AVD Development Image
# This creates a custom Windows 11 image with development tools

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
source "azure-arm" "dev_image" {
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
  vm_size = "Standard_B2als_v2"

  # Shared Image Gallery configuration
  shared_image_gallery_destination {
    subscription         = var.subscription_id
    resource_group       = var.resource_group_name
    gallery_name        = var.shared_image_gallery_name
    image_name          = "avd-dev-image"
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
  name = "dev-image"
  sources = [
    "source.azure-arm.dev_image"
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

  # Install development tools via Chocolatey
  provisioner "powershell" {
    inline = [
      "choco install -y git",
      "choco install -y vscode",
      "choco install -y nodejs",
      "choco install -y python",
      "choco install -y postman",
      "choco install -y azure-cli",
      "choco install -y terraform",
      "choco install -y kubernetes-cli",
      "choco install -y helm",
      "choco install -y powershell-core",
      "choco install -y windows-terminal",
      "choco install -y googlechrome",
      "choco install -y firefox",
      "choco install -y 7zip",
      "choco install -y notepadplusplus",
      "choco install -y slack",
      "choco install -y teams",
      "choco install -y zoom",
      "choco install -y intellijidea-community"
    ]
  }

  # Install Office 365
  provisioner "powershell" {
    script = "./scripts/install-office365.ps1"
  }

  # Install Kiro IDE (placeholder - replace with actual installation)
  provisioner "powershell" {
    inline = [
      "Write-Host 'Installing Kiro IDE...'",
      "# Add Kiro IDE installation commands here",
      "Write-Host 'Kiro IDE installation placeholder completed'"
    ]
  }

  # Install WSL2 and Ubuntu 24.04
  provisioner "powershell" {
    inline = [
      "Write-Host 'Enabling WSL2 and Virtual Machine Platform...' -ForegroundColor Yellow",
      "dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart",
      "dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart",
      "Write-Host 'WSL features enabled' -ForegroundColor Green"
    ]
  }

  # Restart to enable WSL features
  provisioner "windows-restart" {
    restart_timeout = "10m"
  }

  # Install WSL2 kernel update and set default version
  provisioner "powershell" {
    inline = [
      "Write-Host 'Downloading and installing WSL2 kernel update...' -ForegroundColor Yellow",
      "$wslUpdateUrl = 'https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi'",
      "$wslUpdatePath = '$env:TEMP\\wsl_update_x64.msi'",
      "Invoke-WebRequest -Uri $wslUpdateUrl -OutFile $wslUpdatePath -UseBasicParsing",
      "Start-Process msiexec.exe -ArgumentList '/i', $wslUpdatePath, '/quiet', '/norestart' -Wait",
      "wsl --set-default-version 2",
      "Write-Host 'WSL2 kernel update installed and default version set' -ForegroundColor Green"
    ]
  }

  # Install Ubuntu 24.04 LTS
  provisioner "powershell" {
    inline = [
      "Write-Host 'Installing Ubuntu 24.04 LTS...' -ForegroundColor Yellow",
      "$ubuntuUrl = 'https://aka.ms/wslubuntu2404'",
      "$ubuntuPath = '$env:TEMP\\Ubuntu2404.appx'",
      "Invoke-WebRequest -Uri $ubuntuUrl -OutFile $ubuntuPath -UseBasicParsing",
      "Add-AppxPackage -Path $ubuntuPath",
      "Write-Host 'Ubuntu 24.04 LTS installed' -ForegroundColor Green"
    ]
  }

  # Initialize Ubuntu and install Docker
  provisioner "powershell" {
    inline = [
      "Write-Host 'Initializing Ubuntu and installing Docker...' -ForegroundColor Yellow",
      "# Create a script to run in Ubuntu",
      "$ubuntuScript = @'",
      "#!/bin/bash",
      "# Update package list",
      "sudo apt update",
      "",
      "# Install required packages",
      "sudo apt install -y ca-certificates curl gnupg lsb-release",
      "",
      "# Add Docker GPG key",
      "sudo mkdir -p /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      "",
      "# Add Docker repository",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "",
      "# Update package list with Docker repo",
      "sudo apt update",
      "",
      "# Install Docker",
      "sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      "",
      "# Add user to docker group",
      "sudo usermod -aG docker $USER",
      "",
      "# Install additional development tools",
      "sudo apt install -y git curl wget vim nano htop tree jq unzip",
      "",
      "# Install Node.js via NodeSource",
      "curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -",
      "sudo apt install -y nodejs",
      "",
      "# Install Java 17",
      "sudo apt install -y openjdk-17-jdk",
      "",
      "# Install Python and pip",
      "sudo apt install -y python3 python3-pip",
      "",
      "# Install Azure CLI",
      "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash",
      "",
      "# Install kubectl",
      "curl -LO \"https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl\"",
      "sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl",
      "",
      "# Install Terraform",
      "wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg",
      "echo \"deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list",
      "sudo apt update && sudo apt install -y terraform",
      "",
      "echo 'Ubuntu setup completed successfully!'",
      "'@",
      "",
      "# Save the script",
      "$ubuntuScript | Out-File -FilePath '$env:TEMP\\ubuntu-setup.sh' -Encoding UTF8",
      "",
      "# Run the script in Ubuntu (this will create the default user)",
      "ubuntu2404.exe install --root",
      "ubuntu2404.exe run 'useradd -m -s /bin/bash developer && echo \"developer:developer\" | chpasswd && usermod -aG sudo developer'",
      "",
      "# Copy and run the setup script",
      "ubuntu2404.exe run 'cp /mnt/c/Windows/Temp/ubuntu-setup.sh /tmp/ && chmod +x /tmp/ubuntu-setup.sh'",
      "ubuntu2404.exe run 'sudo /tmp/ubuntu-setup.sh'",
      "",
      "Write-Host 'Ubuntu initialization and Docker installation completed' -ForegroundColor Green"
    ]
  }

  # Configure Git for Windows
  provisioner "powershell" {
    inline = [
      "Write-Host 'Configuring Git for Windows...' -ForegroundColor Yellow",
      "git config --global init.defaultBranch main",
      "git config --global core.autocrlf true",
      "git config --global core.editor 'code --wait'",
      "git config --global pull.rebase false",
      "git config --global credential.helper manager-core",
      "Write-Host 'Git for Windows configured' -ForegroundColor Green"
    ]
  }

  # Configure IntelliJ IDEA with plugins
  provisioner "powershell" {
    script = "./scripts/configure-intellij.ps1"
  }

  # Install VS Code extensions
  provisioner "powershell" {
    script = "./scripts/install-vscode-extensions.ps1"
  }

  # Configure Windows features
  provisioner "powershell" {
    inline = [
      "Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart",
      "Enable-WindowsOptionalFeature -Online -FeatureName Containers -All -NoRestart"
    ]
  }

  # Install additional development tools
  provisioner "powershell" {
    script = "./scripts/install-dev-tools.ps1"
  }

  # Configure system settings
  provisioner "powershell" {
    script = "./scripts/configure-system.ps1"
  }

  # Security hardening
  provisioner "powershell" {
    script = "./scripts/security-hardening.ps1"
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