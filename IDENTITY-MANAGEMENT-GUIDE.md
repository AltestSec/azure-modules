# Identity Management Guide for Azure Virtual Desktop

This guide provides comprehensive instructions for configuring identity management in your AVD environment, covering both Azure Entra ID (cloud-native) and Domain Controller (hybrid/on-premises) scenarios.

## 📋 Table of Contents

1. [Overview](#overview)
2. [Azure Entra ID Configuration (Recommended)](#azure-entra-id-configuration-recommended)
3. [Domain Controller Setup (Hybrid Scenarios)](#domain-controller-setup-hybrid-scenarios)
4. [User and Group Management](#user-and-group-management)
5. [Security and Compliance](#security-and-compliance)
6. [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

### Identity Options Comparison

| Feature | Azure Entra ID | Domain Controller | Hybrid (Both) |
|---------|----------------|-------------------|---------------|
| **Complexity** | Low | Medium | High |
| **Management Overhead** | Minimal | High | Medium |
| **On-Premises Integration** | Limited | Full | Full |
| **Cloud-Native Features** | Full | Limited | Full |
| **Cost** | Lower | Higher | Highest |
| **Scalability** | Excellent | Good | Excellent |
| **Security Features** | Advanced | Traditional | Advanced |

### Current Configuration

**Default Setup**: This solution is configured for **Azure Entra ID** authentication, providing:
- ✅ Cloud-native identity management
- ✅ No domain controller required
- ✅ Simplified user management
- ✅ Advanced security features
- ✅ Lower operational overhead

---

## 🌟 Azure Entra ID Configuration (Recommended)

### Prerequisites

- Azure AD tenant with appropriate licenses
- Global Administrator or User Administrator role
- AVD service principal with required permissions

### 1. User and Group Setup

#### Create AVD Users

```powershell
# Connect to Azure AD
Connect-AzureAD

# Create AVD users
$users = @(
    @{ DisplayName = "John Developer"; UserPrincipalName = "john.dev@yourdomain.com"; Department = "Development" },
    @{ DisplayName = "Jane Manager"; UserPrincipalName = "jane.mgmt@yourdomain.com"; Department = "Management" },
    @{ DisplayName = "Bob QA"; UserPrincipalName = "bob.qa@yourdomain.com"; Department = "Quality Assurance" }
)

foreach ($user in $users) {
    $passwordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
    $passwordProfile.Password = "TempPassword123!"
    $passwordProfile.ForceChangePasswordNextLogin = $true
    
    New-AzureADUser -DisplayName $user.DisplayName `
                    -UserPrincipalName $user.UserPrincipalName `
                    -AccountEnabled $true `
                    -PasswordProfile $passwordProfile `
                    -Department $user.Department `
                    -UsageLocation "US"
}
```

#### Create Security Groups

```powershell
# Create AVD security groups
$groups = @(
    @{ Name = "AVD-Developers-EU"; Description = "Developers with access to EU development pool" },
    @{ Name = "AVD-Developers-US"; Description = "Developers with access to US development pool" },
    @{ Name = "AVD-Management-US"; Description = "Management users with access to US management pool" },
    @{ Name = "AVD-Admins"; Description = "AVD administrators with full access" }
)

foreach ($group in $groups) {
    New-AzureADGroup -DisplayName $group.Name `
                     -Description $group.Description `
                     -SecurityEnabled $true `
                     -MailEnabled $false
}
```

#### Assign Users to Groups

```powershell
# Get group and user objects
$devGroupEU = Get-AzureADGroup -Filter "DisplayName eq 'AVD-Developers-EU'"
$devGroupUS = Get-AzureADGroup -Filter "DisplayName eq 'AVD-Developers-US'"
$mgmtGroup = Get-AzureADGroup -Filter "DisplayName eq 'AVD-Management-US'"

$johnUser = Get-AzureADUser -Filter "UserPrincipalName eq 'john.dev@yourdomain.com'"
$janeUser = Get-AzureADUser -Filter "UserPrincipalName eq 'jane.mgmt@yourdomain.com'"

# Add users to appropriate groups
Add-AzureADGroupMember -ObjectId $devGroupEU.ObjectId -RefObjectId $johnUser.ObjectId
Add-AzureADGroupMember -ObjectId $devGroupUS.ObjectId -RefObjectId $johnUser.ObjectId
Add-AzureADGroupMember -ObjectId $mgmtGroup.ObjectId -RefObjectId $janeUser.ObjectId
```

### 2. AVD Application Group Assignments

#### Assign Groups to Application Groups

```bash
# Get application group IDs from Terraform output
DEV_AG_EU=$(terraform output -raw dev_hostpool_eu_id)/applicationGroups/avd-ag-dev-dev-eu
DEV_AG_US=$(terraform output -raw dev_hostpool_us_id)/applicationGroups/avd-ag-dev-dev-us
MGMT_AG_US=$(terraform output -raw mgmt_hostpool_us_id)/applicationGroups/avd-ag-mgmt-dev-us

# Assign groups to application groups
az role assignment create \
  --assignee-object-id $(az ad group show --group "AVD-Developers-EU" --query objectId -o tsv) \
  --role "Desktop Virtualization User" \
  --scope $DEV_AG_EU

az role assignment create \
  --assignee-object-id $(az ad group show --group "AVD-Developers-US" --query objectId -o tsv) \
  --role "Desktop Virtualization User" \
  --scope $DEV_AG_US

az role assignment create \
  --assignee-object-id $(az ad group show --group "AVD-Management-US" --query objectId -o tsv) \
  --role "Desktop Virtualization User" \
  --scope $MGMT_AG_US
```

### 3. Conditional Access Policies

#### Create AVD-Specific Conditional Access Policy

```powershell
# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess"

# Create conditional access policy for AVD
$policy = @{
    displayName = "AVD - Require MFA and Compliant Device"
    state = "enabled"
    conditions = @{
        applications = @{
            includeApplications = @("9cdead84-a844-4324-93f2-b2e6bb768d07") # Windows Virtual Desktop
        }
        users = @{
            includeGroups = @(
                (Get-AzureADGroup -Filter "DisplayName eq 'AVD-Developers-EU'").ObjectId,
                (Get-AzureADGroup -Filter "DisplayName eq 'AVD-Developers-US'").ObjectId,
                (Get-AzureADGroup -Filter "DisplayName eq 'AVD-Management-US'").ObjectId
            )
        }
        locations = @{
            includeLocations = @("All")
            excludeLocations = @("AllTrusted")
        }
    }
    grantControls = @{
        operator = "AND"
        builtInControls = @("mfa", "compliantDevice")
    }
    sessionControls = @{
        signInFrequency = @{
            value = 8
            type = "hours"
            isEnabled = $true
        }
    }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $policy
```

### 4. Device Management with Intune

#### Configure Intune for AVD Session Hosts

```powershell
# Connect to Microsoft Graph
Connect-MgGraph -Scopes "DeviceManagementConfiguration.ReadWrite.All"

# Create device configuration profile for AVD
$deviceConfig = @{
    "@odata.type" = "#microsoft.graph.windows10CustomConfiguration"
    displayName = "AVD Session Host Configuration"
    description = "Custom configuration for AVD session hosts"
    omaSettings = @(
        @{
            "@odata.type" = "#microsoft.graph.omaSettingString"
            displayName = "Disable Windows Consumer Features"
            omaUri = "./Vendor/MSFT/Policy/Config/Experience/AllowWindowsConsumerFeatures"
            value = "<enabled/><data id='AllowWindowsConsumerFeatures' value='0'/>"
        },
        @{
            "@odata.type" = "#microsoft.graph.omaSettingString"
            displayName = "Configure Windows Update for Business"
            omaUri = "./Vendor/MSFT/Policy/Config/Update/BranchReadinessLevel"
            value = "<enabled/><data id='BranchReadinessLevel' value='32'/>"
        }
    )
}

New-MgDeviceManagementDeviceConfiguration -BodyParameter $deviceConfig
```

### 5. Session Host Configuration for Azure AD Join

Update your Terraform configuration to use Azure AD join:

```hcl
# In avd-variables.tf, ensure these settings:
variable "use_aad_join" {
  description = "Use Azure AD join instead of domain join"
  type        = bool
  default     = true
}

variable "domain_join_enabled" {
  description = "Enable domain join for session hosts"
  type        = bool
  default     = false
}
```

---

## 🏢 Domain Controller Setup (Hybrid Scenarios)

### When to Use Domain Controller

Consider domain controller setup when you need:
- Integration with existing on-premises Active Directory
- Group Policy management for session hosts
- Legacy application compatibility
- Centralized authentication for hybrid environments
- External domain integration (different subscription/tenant)

### 1. Domain Controller Deployment

#### Option A: Deploy Domain Controller in Azure

```hcl
# Add to your Terraform configuration
resource "azurerm_windows_virtual_machine" "domain_controller" {
  name                = "vm-dc-${var.environment}"
  resource_group_name = azurerm_resource_group.avd_us.name
  location            = azurerm_resource_group.avd_us.location
  size                = "Standard_D2s_v3"
  admin_username      = var.dc_admin_username
  admin_password      = var.dc_admin_password

  network_interface_ids = [
    azurerm_network_interface.domain_controller.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  tags = merge(local.common_tags, {
    Role = "DomainController"
  })
}

# Network interface for domain controller
resource "azurerm_network_interface" "domain_controller" {
  name                = "nic-dc-${var.environment}"
  location            = azurerm_resource_group.avd_us.location
  resource_group_name = azurerm_resource_group.avd_us.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.domain_controller.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.2.3.4"
  }

  tags = local.common_tags
}

# Dedicated subnet for domain controller
resource "azurerm_subnet" "domain_controller" {
  name                 = "snet-dc-${var.environment}"
  resource_group_name  = azurerm_resource_group.avd_us.name
  virtual_network_name = azurerm_virtual_network.avd_us.name
  address_prefixes     = ["10.2.3.0/24"]
}
```

#### Domain Controller Configuration Script

```powershell
# PowerShell script to configure domain controller
# Save as: configure-domain-controller.ps1

param(
    [Parameter(Mandatory=$true)]
    [string]$DomainName,
    
    [Parameter(Mandatory=$true)]
    [string]$SafeModePassword
)

# Install AD DS role
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Import AD DS deployment module
Import-Module ADDSDeployment

# Create new forest and domain
Install-ADDSForest `
    -DomainName $DomainName `
    -DomainNetbiosName ($DomainName.Split('.')[0].ToUpper()) `
    -SafeModeAdministratorPassword (ConvertTo-SecureString $SafeModePassword -AsPlainText -Force) `
    -InstallDns:$true `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -LogPath "C:\Windows\NTDS" `
    -SysvolPath "C:\Windows\SYSVOL" `
    -Force:$true

# Configure DNS forwarders
Add-DnsServerForwarder -IPAddress "168.63.129.16" # Azure DNS
Add-DnsServerForwarder -IPAddress "8.8.8.8"       # Google DNS

Write-Host "Domain controller configuration completed. System will restart."
```

#### Run Domain Controller Configuration

```bash
# Execute domain controller setup via Azure VM extension
az vm extension set \
  --resource-group rg-avd-dev-us \
  --vm-name vm-dc-dev \
  --name CustomScriptExtension \
  --publisher Microsoft.Compute \
  --settings '{
    "fileUris": ["https://raw.githubusercontent.com/your-repo/scripts/configure-domain-controller.ps1"],
    "commandToExecute": "powershell -ExecutionPolicy Unrestricted -File configure-domain-controller.ps1 -DomainName \"avd.local\" -SafeModePassword \"YourSafeModePassword123!\""
  }'
```

### 2. DNS Configuration

#### Update VNet DNS Settings

```hcl
# Update virtual network to use domain controller as DNS server
resource "azurerm_virtual_network" "avd_us" {
  name                = "vnet-avd-${var.environment}-us"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.avd_us.location
  resource_group_name = azurerm_resource_group.avd_us.name
  
  # Use domain controller as DNS server
  dns_servers = ["10.2.3.4", "168.63.129.16"]
  
  tags = local.common_tags
}
```

### 3. Session Host Domain Join Configuration

#### Update Session Host Module for Domain Join

```hcl
# In your session host module call, enable domain join
module "avd_sessionhosts_dev_us" {
  source = "./modules/avd-sessionhosts"

  # ... other configuration ...

  # Domain join configuration
  domain_join_enabled  = true
  domain_name         = "avd.local"
  domain_ou_path      = "OU=AVD,OU=Computers,DC=avd,DC=local"
  domain_join_username = "avd\\administrator"
  domain_join_password = var.domain_admin_password
  aad_join            = false

  # ... rest of configuration ...
}
```

### 4. Active Directory User and Group Management

#### Create Organizational Units

```powershell
# Connect to domain controller and create OUs
Import-Module ActiveDirectory

# Create main AVD OU structure
New-ADOrganizationalUnit -Name "AVD" -Path "DC=avd,DC=local"
New-ADOrganizationalUnit -Name "Users" -Path "OU=AVD,DC=avd,DC=local"
New-ADOrganizationalUnit -Name "Groups" -Path "OU=AVD,DC=avd,DC=local"
New-ADOrganizationalUnit -Name "Computers" -Path "OU=AVD,DC=avd,DC=local"
New-ADOrganizationalUnit -Name "ServiceAccounts" -Path "OU=AVD,DC=avd,DC=local"

# Create sub-OUs for different pools
New-ADOrganizationalUnit -Name "Development" -Path "OU=Users,OU=AVD,DC=avd,DC=local"
New-ADOrganizationalUnit -Name "Management" -Path "OU=Users,OU=AVD,DC=avd,DC=local"
```

#### Create Users and Groups

```powershell
# Create security groups
$groups = @(
    @{ Name = "AVD-Developers-EU"; Path = "OU=Groups,OU=AVD,DC=avd,DC=local"; Description = "EU Development Pool Users" },
    @{ Name = "AVD-Developers-US"; Path = "OU=Groups,OU=AVD,DC=avd,DC=local"; Description = "US Development Pool Users" },
    @{ Name = "AVD-Management-US"; Path = "OU=Groups,OU=AVD,DC=avd,DC=local"; Description = "US Management Pool Users" },
    @{ Name = "AVD-Admins"; Path = "OU=Groups,OU=AVD,DC=avd,DC=local"; Description = "AVD Administrators" }
)

foreach ($group in $groups) {
    New-ADGroup -Name $group.Name `
                -GroupScope Global `
                -GroupCategory Security `
                -Path $group.Path `
                -Description $group.Description
}

# Create users
$users = @(
    @{ Name = "John Developer"; SamAccountName = "john.dev"; Path = "OU=Development,OU=Users,OU=AVD,DC=avd,DC=local"; Groups = @("AVD-Developers-EU", "AVD-Developers-US") },
    @{ Name = "Jane Manager"; SamAccountName = "jane.mgmt"; Path = "OU=Management,OU=Users,OU=AVD,DC=avd,DC=local"; Groups = @("AVD-Management-US") }
)

foreach ($user in $users) {
    $password = ConvertTo-SecureString "TempPassword123!" -AsPlainText -Force
    
    New-ADUser -Name $user.Name `
               -SamAccountName $user.SamAccountName `
               -UserPrincipalName "$($user.SamAccountName)@avd.local" `
               -Path $user.Path `
               -AccountPassword $password `
               -Enabled $true `
               -ChangePasswordAtLogon $true
    
    # Add user to groups
    foreach ($groupName in $user.Groups) {
        Add-ADGroupMember -Identity $groupName -Members $user.SamAccountName
    }
}
```

### 5. Group Policy Configuration

#### Create AVD-Specific GPOs

```powershell
# Import Group Policy module
Import-Module GroupPolicy

# Create GPO for AVD session hosts
$gpoName = "AVD Session Host Configuration"
New-GPO -Name $gpoName -Comment "Configuration for AVD session hosts"

# Link GPO to AVD Computers OU
New-GPLink -Name $gpoName -Target "OU=Computers,OU=AVD,DC=avd,DC=local"

# Configure specific settings
Set-GPRegistryValue -Name $gpoName -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -ValueName "fEnableTimeZoneRedirection" -Type DWord -Value 1
Set-GPRegistryValue -Name $gpoName -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -ValueName "fDisableCdm" -Type DWord -Value 0
Set-GPRegistryValue -Name $gpoName -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -ValueName "fDisableCam" -Type DWord -Value 0

# Configure Windows Update settings
Set-GPRegistryValue -Name $gpoName -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "AUOptions" -Type DWord -Value 4
Set-GPRegistryValue -Name $gpoName -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "ScheduledInstallDay" -Type DWord -Value 0
Set-GPRegistryValue -Name $gpoName -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "ScheduledInstallTime" -Type DWord -Value 3
```

### 6. Azure AD Connect (Hybrid Identity)

#### Install and Configure Azure AD Connect

```powershell
# Download and install Azure AD Connect
$aadConnectUrl = "https://download.microsoft.com/download/B/0/0/B00291D0-5A83-4DE7-86F5-980BC00DE05A/AzureADConnect.msi"
$aadConnectPath = "$env:TEMP\AzureADConnect.msi"

Invoke-WebRequest -Uri $aadConnectUrl -OutFile $aadConnectPath
Start-Process msiexec.exe -ArgumentList "/i", $aadConnectPath, "/quiet" -Wait

# Configure Azure AD Connect (requires manual configuration via GUI or PowerShell module)
Write-Host "Azure AD Connect installed. Complete configuration via the Azure AD Connect wizard."
Write-Host "Configure the following:"
Write-Host "  - Connect to Azure AD tenant"
Write-Host "  - Connect to on-premises AD"
Write-Host "  - Configure user sign-in (Password Hash Sync recommended)"
Write-Host "  - Select OUs to synchronize (OU=AVD,DC=avd,DC=local)"
Write-Host "  - Configure optional features as needed"
```

---

## 👥 User and Group Management

### Azure Entra ID User Management

#### Bulk User Creation

```powershell
# Bulk create users from CSV
$csvPath = "C:\temp\avd-users.csv"
$users = Import-Csv $csvPath

foreach ($user in $users) {
    $passwordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
    $passwordProfile.Password = $user.TempPassword
    $passwordProfile.ForceChangePasswordNextLogin = $true
    
    try {
        New-AzureADUser -DisplayName $user.DisplayName `
                        -UserPrincipalName $user.UserPrincipalName `
                        -AccountEnabled $true `
                        -PasswordProfile $passwordProfile `
                        -Department $user.Department `
                        -JobTitle $user.JobTitle `
                        -UsageLocation $user.Country
        
        Write-Host "Created user: $($user.DisplayName)" -ForegroundColor Green
    } catch {
        Write-Error "Failed to create user $($user.DisplayName): $($_.Exception.Message)"
    }
}
```

#### Dynamic Group Membership

```powershell
# Create dynamic groups based on user attributes
$dynamicGroups = @(
    @{
        Name = "AVD-Developers-Dynamic"
        Description = "Dynamic group for developers"
        MembershipRule = "(user.department -eq `"Development`") and (user.accountEnabled -eq true)"
    },
    @{
        Name = "AVD-Management-Dynamic"
        Description = "Dynamic group for management"
        MembershipRule = "(user.department -eq `"Management`") and (user.accountEnabled -eq true)"
    }
)

foreach ($group in $dynamicGroups) {
    New-AzureADMSGroup -DisplayName $group.Name `
                       -Description $group.Description `
                       -SecurityEnabled $true `
                       -MailEnabled $false `
                       -GroupTypes @("DynamicMembership") `
                       -MembershipRule $group.MembershipRule `
                       -MembershipRuleProcessingState "On"
}
```

### Domain Controller User Management

#### Automated User Provisioning

```powershell
# Automated user provisioning script
param(
    [Parameter(Mandatory=$true)]
    [string]$CsvPath
)

Import-Module ActiveDirectory

$users = Import-Csv $CsvPath

foreach ($user in $users) {
    try {
        $password = ConvertTo-SecureString $user.TempPassword -AsPlainText -Force
        
        New-ADUser -Name $user.DisplayName `
                   -GivenName $user.FirstName `
                   -Surname $user.LastName `
                   -SamAccountName $user.SamAccountName `
                   -UserPrincipalName "$($user.SamAccountName)@avd.local" `
                   -Path $user.OUPath `
                   -AccountPassword $password `
                   -Enabled $true `
                   -ChangePasswordAtLogon $true `
                   -Department $user.Department `
                   -Title $user.JobTitle
        
        # Add to groups
        if ($user.Groups) {
            $groups = $user.Groups -split ';'
            foreach ($groupName in $groups) {
                Add-ADGroupMember -Identity $groupName -Members $user.SamAccountName
            }
        }
        
        Write-Host "Created user: $($user.DisplayName)" -ForegroundColor Green
    } catch {
        Write-Error "Failed to create user $($user.DisplayName): $($_.Exception.Message)"
    }
}
```

---

## 🔐 Security and Compliance

### Azure Entra ID Security Features

#### Configure Identity Protection

```powershell
# Connect to Microsoft Graph
Connect-MgGraph -Scopes "IdentityRiskyUser.ReadWrite.All", "IdentityRiskEvent.Read.All"

# Configure user risk policy
$userRiskPolicy = @{
    displayName = "AVD User Risk Policy"
    state = "enabled"
    conditions = @{
        userRiskLevels = @("high")
        applications = @{
            includeApplications = @("All")
        }
        users = @{
            includeGroups = @(
                (Get-AzureADGroup -Filter "DisplayName eq 'AVD-Developers-EU'").ObjectId,
                (Get-AzureADGroup -Filter "DisplayName eq 'AVD-Developers-US'").ObjectId,
                (Get-AzureADGroup -Filter "DisplayName eq 'AVD-Management-US'").ObjectId
            )
        }
    }
    grantControls = @{
        operator = "OR"
        builtInControls = @("passwordChange")
    }
}

# Configure sign-in risk policy
$signInRiskPolicy = @{
    displayName = "AVD Sign-in Risk Policy"
    state = "enabled"
    conditions = @{
        signInRiskLevels = @("medium", "high")
        applications = @{
            includeApplications = @("9cdead84-a844-4324-93f2-b2e6bb768d07") # Windows Virtual Desktop
        }
        users = @{
            includeGroups = @(
                (Get-AzureADGroup -Filter "DisplayName eq 'AVD-Developers-EU'").ObjectId,
                (Get-AzureADGroup -Filter "DisplayName eq 'AVD-Developers-US'").ObjectId,
                (Get-AzureADGroup -Filter "DisplayName eq 'AVD-Management-US'").ObjectId
            )
        }
    }
    grantControls = @{
        operator = "OR"
        builtInControls = @("mfa")
    }
}
```

### Domain Controller Security

#### Configure Fine-Grained Password Policy

```powershell
# Create fine-grained password policy for AVD users
Import-Module ActiveDirectory

New-ADFineGrainedPasswordPolicy -Name "AVD-Password-Policy" `
                                -Precedence 10 `
                                -ComplexityEnabled $true `
                                -Description "Password policy for AVD users" `
                                -DisplayName "AVD Password Policy" `
                                -LockoutDuration "00:30:00" `
                                -LockoutObservationWindow "00:30:00" `
                                -LockoutThreshold 5 `
                                -MaxPasswordAge "90.00:00:00" `
                                -MinPasswordAge "1.00:00:00" `
                                -MinPasswordLength 12 `
                                -PasswordHistoryCount 12 `
                                -ReversibleEncryptionEnabled $false

# Apply policy to AVD groups
Add-ADFineGrainedPasswordPolicySubject -Identity "AVD-Password-Policy" -Subjects "AVD-Developers-EU"
Add-ADFineGrainedPasswordPolicySubject -Identity "AVD-Password-Policy" -Subjects "AVD-Developers-US"
Add-ADFineGrainedPasswordPolicySubject -Identity "AVD-Password-Policy" -Subjects "AVD-Management-US"
```

---

## 🔧 Troubleshooting

### Common Azure Entra ID Issues

#### User Cannot Access AVD

```powershell
# Check user's group membership
$user = Get-AzureADUser -Filter "UserPrincipalName eq 'user@domain.com'"
$groups = Get-AzureADUserMembership -ObjectId $user.ObjectId

Write-Host "User groups:"
$groups | ForEach-Object { Write-Host "  - $($_.DisplayName)" }

# Check application group assignments
$avdAppId = "9cdead84-a844-4324-93f2-b2e6bb768d07"
$assignments = Get-AzureADServiceAppRoleAssignment -ObjectId (Get-AzureADServicePrincipal -Filter "AppId eq '$avdAppId'").ObjectId

Write-Host "AVD role assignments:"
$assignments | Where-Object { $_.PrincipalId -eq $user.ObjectId } | ForEach-Object {
    Write-Host "  - Role: $($_.Id), Resource: $($_.ResourceDisplayName)"
}
```

#### Conditional Access Policy Issues

```powershell
# Check conditional access policy evaluation
Connect-MgGraph -Scopes "Policy.Read.All", "AuditLog.Read.All"

# Get sign-in logs for troubleshooting
$signInLogs = Get-MgAuditLogSignIn -Filter "userPrincipalName eq 'user@domain.com'" -Top 10

$signInLogs | ForEach-Object {
    Write-Host "Sign-in: $($_.CreatedDateTime)"
    Write-Host "  Status: $($_.Status.ErrorCode) - $($_.Status.FailureReason)"
    Write-Host "  App: $($_.AppDisplayName)"
    Write-Host "  Conditional Access:"
    $_.ConditionalAccessStatus | ForEach-Object {
        Write-Host "    - $($_.DisplayName): $($_.Result)"
    }
}
```

### Common Domain Controller Issues

#### Domain Join Failures

```powershell
# Check domain controller connectivity from session host
Test-NetConnection -ComputerName "dc.avd.local" -Port 389
Test-NetConnection -ComputerName "dc.avd.local" -Port 636
Test-NetConnection -ComputerName "dc.avd.local" -Port 3268

# Check DNS resolution
nslookup avd.local
nslookup _ldap._tcp.avd.local

# Test domain join manually
$credential = Get-Credential -Message "Enter domain admin credentials"
Add-Computer -DomainName "avd.local" -Credential $credential -Restart
```

#### Group Policy Issues

```powershell
# Force Group Policy update on session host
gpupdate /force

# Check Group Policy application
gpresult /r
gpresult /h C:\temp\gpresult.html

# Check specific policy settings
Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
```

### Session Host Registration Issues

```powershell
# Check AVD agent status
Get-Service -Name RDAgentBootLoader
Get-Service -Name RDAgent

# Check registration token
$regToken = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\RDInfraAgent" -Name "RegistrationToken" -ErrorAction SilentlyContinue
if ($regToken) {
    Write-Host "Registration token exists"
} else {
    Write-Host "Registration token missing - re-register session host"
}

# Re-register session host if needed
$hostPoolToken = "YOUR_HOST_POOL_REGISTRATION_TOKEN"
cd "C:\Program Files\Microsoft RDInfra"
.\AgentInstall.msi REGISTRATIONTOKEN=$hostPoolToken /quiet
```

---

## 📞 Support and Resources

### Documentation Links
- [Azure Virtual Desktop Documentation](https://docs.microsoft.com/en-us/azure/virtual-desktop/)
- [Azure AD Documentation](https://docs.microsoft.com/en-us/azure/active-directory/)
- [Windows Server Active Directory](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/)

### PowerShell Modules
```powershell
# Install required PowerShell modules
Install-Module -Name AzureAD -Force
Install-Module -Name Microsoft.Graph -Force
Install-Module -Name ActiveDirectory -Force
Install-Module -Name Az.DesktopVirtualization -Force
```

### Useful Commands Reference

#### Azure Entra ID
```powershell
# Connect to Azure AD
Connect-AzureAD

# List all AVD-related groups
Get-AzureADGroup -Filter "startswith(DisplayName,'AVD-')"

# Get user's AVD permissions
Get-AzureADUserAppRoleAssignment -ObjectId $userId
```

#### Domain Controller
```powershell
# Import Active Directory module
Import-Module ActiveDirectory

# List all AVD users
Get-ADUser -Filter * -SearchBase "OU=AVD,DC=avd,DC=local"

# Check group membership
Get-ADGroupMember -Identity "AVD-Developers-EU"
```

This comprehensive guide provides everything needed to configure identity management for your AVD environment, whether using modern Azure Entra ID or traditional domain controllers.