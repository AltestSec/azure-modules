# AVD Session Hosts Module Variables

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure location for the resources"
  type        = string
}

variable "pool_name" {
  description = "Name of the host pool"
  type        = string
}

variable "pool_type" {
  description = "Type of the pool (dev, management, etc.)"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet for session hosts"
  type        = string
}

variable "session_host_count" {
  description = "Number of session hosts to create"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "Size of the virtual machines"
  type        = string
  default     = "Standard_B2als_v2"
}

variable "admin_username" {
  description = "Admin username for the VMs"
  type        = string
  default     = "avdadmin"
}

variable "admin_password" {
  description = "Admin password for the VMs"
  type        = string
  sensitive   = true
}

variable "os_disk_type" {
  description = "Type of OS disk"
  type        = string
  default     = "Standart_LRS"
}

variable "os_disk_size_gb" {
  description = "Size of OS disk in GB"
  type        = number
  default     = 128
}

# Custom Image Variables
variable "use_custom_image" {
  description = "Whether to use a custom image from Shared Image Gallery"
  type        = bool
  default     = false
}

variable "custom_image_name" {
  description = "Name of the custom image in Shared Image Gallery"
  type        = string
  default     = ""
}

variable "shared_image_gallery_name" {
  description = "Name of the Shared Image Gallery"
  type        = string
  default     = ""
}

variable "shared_image_gallery_rg" {
  description = "Resource group of the Shared Image Gallery"
  type        = string
  default     = ""
}

# Marketplace Image Variables
variable "vm_image_publisher" {
  description = "Publisher of the VM image"
  type        = string
  default     = "MicrosoftWindowsDesktop"
}

variable "vm_image_offer" {
  description = "Offer of the VM image"
  type        = string
  default     = "Windows-11"
}

variable "vm_image_sku" {
  description = "SKU of the VM image"
  type        = string
  default     = "win11-22h2-avd"
}

variable "vm_image_version" {
  description = "Version of the VM image"
  type        = string
  default     = "latest"
}

# Domain Join Variables
variable "domain_join_enabled" {
  description = "Whether to join VMs to domain"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Domain name to join"
  type        = string
  default     = ""
}

variable "domain_ou_path" {
  description = "OU path for domain join"
  type        = string
  default     = ""
}

variable "domain_join_username" {
  description = "Username for domain join"
  type        = string
  default     = ""
}

variable "domain_join_password" {
  description = "Password for domain join"
  type        = string
  default     = ""
  sensitive   = true
}

# AVD Configuration Variables
variable "host_pool_name" {
  description = "Name of the host pool"
  type        = string
}

variable "host_pool_token" {
  description = "Registration token for the host pool"
  type        = string
  sensitive   = true
}

variable "aad_join" {
  description = "Whether to use Azure AD join"
  type        = bool
  default     = true
}

# Auto-shutdown Variables
variable "auto_shutdown_enabled" {
  description = "Enable auto-shutdown for session hosts"
  type        = bool
  default     = true
}

variable "shutdown_time" {
  description = "Time to shutdown VMs (24h format)"
  type        = string
  default     = "19:00"
}

variable "timezone" {
  description = "Timezone for scheduling"
  type        = string
  default     = "UTC"
}

variable "shutdown_notification_webhook" {
  description = "Webhook URL for shutdown notifications"
  type        = string
  default     = ""
}

variable "shutdown_notification_email" {
  description = "Email for shutdown notifications"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}