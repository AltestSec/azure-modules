# Azure Virtual Desktop (AVD) Infrastructure

A comprehensive, enterprise-ready Azure Virtual Desktop solution with multi-region deployment, custom images, intelligent scaling, and security hardening.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           Azure Virtual Desktop Solution                        │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────┐                    ┌─────────────────┐                   │
│  │   West Europe   │                    │    East US      │                   │
│  │                 │                    │                 │                   │
│  │ ┌─────────────┐ │                    │ ┌─────────────┐ │                   │
│  │ │ Dev Pool EU │ │                    │ │ Dev Pool US │ │                   │
│  │ │ 4x D8s_v3   │ │                    │ │ 6x D8s_v3   │ │                   │
│  │ │ 32GB RAM    │ │                    │ │ 32GB RAM    │ │                   │
│  │ └─────────────┘ │                    │ └─────────────┘ │                   │
│  │                 │                    │                 │                   │
│  │ ┌─────────────┐ │                    │ ┌─────────────┐ │                   │
│  │ │Shared Image │ │                    │ │ Mgmt Pool   │ │                   │
│  │ │  Gallery    │ │                    │ │ 3x D4s_v3   │ │                   │
│  │ │             │ │                    │ │ 16GB RAM    │ │                   │
│  │ └─────────────┘ │                    │ └─────────────┘ │                   │
│  │                 │                    │                 │                   │
│  │ ┌─────────────┐ │                    │                 │                   │
│  │ │   ACR       │ │                    │                 │                   │
│  │ │ Container   │ │                    │                 │                   │
│  │ │ Registry    │ │                    │                 │                   │
│  │ └─────────────┘ │                    │                 │                   │
│  └─────────────────┘                    └─────────────────┘                   │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 🚀 Features

### Multi-Region Deployment
- **West Europe**: Development pool with 4 high-performance VMs (8 vCPU, 32GB RAM)
- **East US**: Development pool (6 VMs) + Management pool (3 VMs, 4 vCPU, 16GB RAM)

### Custom Images
- **Development Image**: VS Code, Kiro IDE, Docker, Git, Office Suite, Development tools
- **Management Image**: Office Suite, Loop, Confluence, Browser tools, Business applications

### Intelligent Scaling & Scheduling
- **Auto-scaling**: Based on user demand and time of day
- **Hungarian Holiday Support**: Automatic shutdown on Hungarian public holidays
- **Work Hours Optimization**: 9 AM - 6 PM CET/EST scheduling
- **Weekend Management**: Reduced capacity on weekends

### Security & Compliance
- **Azure AD Integration**: Seamless authentication
- **Network Security Groups**: Restricted access
- **Private Endpoints**: Secure connectivity
- **Security Hardening**: CIS benchmarks compliance
- **BitLocker Encryption**: Data protection at rest

### Image Management
- **Azure Container Registry**: Secure image storage
- **Shared Image Gallery**: Multi-region image replication
- **Automated Building**: Packer-based image creation
- **Version Control**: Semantic versioning for images

## 📋 Prerequisites

### Azure Requirements
- Azure subscription with sufficient quotas
- Service Principal with Contributor access
- Azure AD tenant for user authentication

### Local Development
- Terraform >= 1.7.0
- Azure CLI >= 2.50.0
- Packer >= 1.9.0 (for image building)
- PowerShell >= 7.0

### Network Requirements
- Virtual network address space planning
- DNS configuration for domain join (optional)
- Firewall rules for AVD traffic

## 🛠️ Quick Start

### 1. Clone and Configure

```bash
git clone <repository-url>
cd az_payground

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your Azure details
```

### 2. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file="terraform.tfvars"

# Deploy infrastructure
terraform apply -var-file="terraform.tfvars"
```

### 3. Build Custom Images

```bash
# Navigate to image building directory
cd image-building

# Build development image
packer build -var-file="../terraform.tfvars" dev-image.pkr.hcl

# Build management image
packer build -var-file="../terraform.tfvars" mgmt-image.pkr.hcl
```

## 🔧 Configuration

### Pool Configuration

| Pool | Location | VM Size | vCPU | RAM | Storage | Max Sessions | Image Type |
|------|----------|---------|------|-----|---------|--------------|------------|
| Dev EU | West Europe | Standard_D8s_v3 | 8 | 32GB | Premium SSD | 4 | Development |
| Dev US | East US | Standard_D8s_v3 | 8 | 32GB | Premium SSD | 4 | Development |
| Mgmt US | East US | Standard_D4s_v3 | 4 | 16GB | Premium SSD | 6 | Management |

### Scaling Configuration

```hcl
# Example scaling configuration
variable "dev_pool_size_eu" {
  description = "EU Development Pool Size"
  type        = number
  default     = 4
}

variable "dev_pool_size_us" {
  description = "US Development Pool Size"
  type        = number
  default     = 6
}

variable "mgmt_pool_size_us" {
  description = "US Management Pool Size"
  type        = number
  default     = 3
}
```

### Work Hours Configuration

```hcl
# Work hours are configurable per region
work_hours_start = "09:00"
peak_hours_start = "10:00"
ramp_down_start  = "18:00"
off_peak_start   = "22:00"
```

## 🖼️ Custom Images

### Development Image Includes:
- **IDEs**: VS Code, IntelliJ IDEA Community Edition (with Git, Node.js, Java plugins)
- **Development Tools**: Git for Windows, Node.js, Python with pipx, .NET SDK
- **Python Tools**: pipx package manager with black, flake8, pytest, poetry, cookiecutter, pre-commit
- **Cloud Tools**: Azure CLI, Terraform, Kubernetes CLI
- **Databases**: MongoDB Compass, DBeaver
- **Communication**: Teams, Slack, Zoom
- **Office Suite**: Microsoft 365 Apps
- **WSL2**: Ubuntu 24.04 LTS with Docker, development tools
- **Java Development**: OpenJDK 17, Maven, Gradle

### Management Image Includes:
- **Office Suite**: Microsoft 365 Apps
- **Collaboration**: Microsoft Loop, Confluence tools
- **Browsers**: Chrome, Firefox, Edge with business extensions
- **Business Intelligence**: Power BI, Tableau Desktop
- **Communication**: Teams, Slack, Zoom, Skype
- **Utilities**: 7-Zip, Adobe Reader, Paint.NET

## 🔐 Security Features

### Network Security
- Network Security Groups with minimal required access
- Private endpoints for Azure services
- VNet peering for multi-region connectivity
- Azure Firewall integration ready

### Identity & Access
- Azure AD integration for seamless SSO
- Conditional Access policies support
- Multi-factor authentication enforcement
- Role-based access control (RBAC)

### Data Protection
- BitLocker encryption for OS disks
- Azure Disk Encryption for data disks
- Backup and disaster recovery
- Data loss prevention policies

### Compliance
- CIS benchmarks implementation
- Security hardening scripts
- Audit logging and monitoring
- Compliance reporting

## 📊 Monitoring & Alerting

### Log Analytics Integration
- Centralized logging for all AVD components
- Performance metrics collection
- User session analytics
- Security event monitoring

### Azure Monitor Alerts
- VM performance alerts
- User connection failures
- Resource utilization thresholds
- Security incident notifications

### Cost Management
- Resource tagging for cost allocation
- Budget alerts and controls
- Usage optimization recommendations
- Reserved instance planning

## 🚀 CI/CD Pipeline

### GitHub Actions Workflow

The solution includes a comprehensive GitHub Actions workflow with:

- **Security Scanning**: Checkov and TFSec integration
- **Terraform Validation**: Syntax and configuration validation
- **Multi-Environment Support**: Dev, Staging, Production
- **Image Building**: Automated Packer builds
- **Deployment Approval**: Environment-specific approvals

### Pipeline Parameters

```yaml
# Configurable parameters
dev_pool_size_eu: '4'      # EU Development pool size
dev_pool_size_us: '6'      # US Development pool size  
mgmt_pool_size_us: '3'     # US Management pool size
environment: 'dev'         # Target environment
action: 'plan'             # Terraform action
enable_image_building: true # Enable custom image building
enable_security_scanning: true # Enable security scans
```

## 🔄 Scaling & Automation

### Auto-Scaling Features
- **Demand-based scaling**: Automatic VM provisioning based on user load
- **Time-based scaling**: Predictive scaling for known usage patterns
- **Cost optimization**: Automatic shutdown during off-hours
- **Holiday scheduling**: Hungarian holiday calendar integration

### Scaling Policies

```hcl
# Example scaling schedule
schedule {
  name                     = "work_hours"
  days_of_week            = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
  ramp_up_start_time      = "09:00"
  peak_start_time         = "10:00"
  ramp_down_start_time    = "18:00"
  off_peak_start_time     = "22:00"
}
```

## 🛡️ Identity Management Options

This solution supports multiple identity management approaches to fit different organizational needs:

### 🌟 Azure Entra ID (Default & Recommended)
- **Current Configuration**: The solution is pre-configured for Azure Entra ID
- **Benefits**: Cloud-native, no domain controller required, advanced security features
- **Use Case**: Modern organizations, cloud-first approach, simplified management
- **Documentation**: See [Identity Management Guide](IDENTITY-MANAGEMENT-GUIDE.md#azure-entra-id-configuration-recommended)

### 🏢 Domain Controller (Hybrid Scenarios)
- **When to Use**: On-premises AD integration, legacy applications, Group Policy requirements
- **Options**: Azure-hosted DC, on-premises integration, external domain support
- **Use Case**: Hybrid environments, existing AD infrastructure, compliance requirements
- **Documentation**: See [Identity Management Guide](IDENTITY-MANAGEMENT-GUIDE.md#domain-controller-setup-hybrid-scenarios)

### 🔄 Hybrid Identity (Best of Both)
- **Approach**: Azure AD Connect for synchronization
- **Benefits**: Cloud features with on-premises integration
- **Use Case**: Large enterprises with existing AD investments
- **Documentation**: See [Identity Management Guide](IDENTITY-MANAGEMENT-GUIDE.md#azure-ad-connect-hybrid-identity)

### Quick Configuration Guide

#### For Azure Entra ID (Current Setup):
```bash
# No additional configuration needed - ready to use!
# Just assign users to AVD application groups
az role assignment create \
  --assignee user@yourdomain.com \
  --role "Desktop Virtualization User" \
  --scope /subscriptions/.../applicationGroups/...
```

#### For Domain Controller Setup:
```hcl
# Update terraform variables
domain_join_enabled = true
domain_name        = "yourdomain.local"
use_aad_join       = false

# Deploy domain controller (see guide for details)
terraform apply -var="deploy_domain_controller=true"
```

**📖 Complete Documentation**: For detailed setup instructions, user management, security configuration, and troubleshooting, see the comprehensive [Identity Management Guide](IDENTITY-MANAGEMENT-GUIDE.md).

## 📈 Performance Optimization

### VM Performance
- Premium SSD storage for optimal I/O
- Accelerated networking enabled
- Optimal VM sizes for workload types
- Memory and CPU optimization

### Network Optimization
- Regional proximity for users
- Azure backbone network utilization
- CDN integration for content delivery
- Bandwidth optimization

### Application Optimization
- Office 365 optimization for AVD
- Browser performance tuning
- Development tool configuration
- Resource usage monitoring

## 💰 Cost Management

### Cost Optimization Strategies
- **Auto-shutdown**: 60%+ cost savings during off-hours
- **Right-sizing**: Optimal VM sizes for workload requirements
- **Reserved Instances**: Long-term cost savings
- **Spot Instances**: Development environment cost reduction

### Cost Monitoring
- Resource tagging for cost allocation
- Budget alerts and controls
- Usage analytics and reporting
- Optimization recommendations

## 🔧 Troubleshooting

### Common Issues

#### 1. VM Deployment Failures
```bash
# Check quota limits
az vm list-usage --location "West Europe" --output table

# Verify service principal permissions
az role assignment list --assignee <service-principal-id>
```

#### 2. Image Building Issues
```bash
# Check Packer logs
packer build -debug dev-image.pkr.hcl

# Verify Azure permissions for image building
az role assignment create --assignee <sp-id> --role "Virtual Machine Contributor"
```

#### 3. User Connection Issues
```bash
# Check AVD agent status
Get-Service -Name RDAgentBootLoader
Get-Service -Name RDAgent

# Verify registration token
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\RDInfraAgent" -Name "RegistrationToken"
```

### Support Resources
- Azure AVD documentation
- Community forums and support
- Microsoft support tickets
- Internal knowledge base

## 📚 Additional Resources

### Documentation
- [Azure Virtual Desktop Documentation](https://docs.microsoft.com/en-us/azure/virtual-desktop/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Packer Azure Builder](https://www.packer.io/plugins/builders/azure)
- **[Identity Management Guide](IDENTITY-MANAGEMENT-GUIDE.md)**: Comprehensive guide for Azure Entra ID and Domain Controller setup
- **[Changelog](CHANGELOG.md)**: Complete project history and version information

### Best Practices
- [AVD Security Best Practices](https://docs.microsoft.com/en-us/azure/virtual-desktop/security-guide)
- [Performance Tuning Guide](https://docs.microsoft.com/en-us/azure/virtual-desktop/set-up-customize-master-image)
- [Cost Optimization Guide](https://docs.microsoft.com/en-us/azure/virtual-desktop/optimize-costs)

### Community
- Azure Virtual Desktop Tech Community
- Terraform Azure Provider Issues
- GitHub Discussions and Issues

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests and documentation
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Contact the infrastructure team
- Check the troubleshooting guide
- Review Azure documentation

---

**Built with ❤️ for modern remote work environments**