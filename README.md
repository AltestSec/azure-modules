# Azure Playground Infrastructure

This Terraform configuration creates a complete Azure infrastructure with VMs, Service Bus, and intelligent scheduling based on Hungarian holidays and work hours.

## Features

- **Scalable VM Infrastructure**: Create 1-5 VMs of different pool types (web, api, worker)
- **Azure Service Bus**: Messaging infrastructure with topics and subscriptions
- **Remote State Storage**: Terraform state stored in Azure Storage
- **Intelligent VM Scheduling**: 
  - Auto-shutdown outside work hours (9 AM - 6 PM CET)
  - Shutdown on weekends and Hungarian holidays
  - Manual control via Azure Functions
- **CI/CD Pipelines**: Both Azure DevOps and GitHub Actions support
- **Security**: Network security groups, SSH key authentication

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Azure VNet    │    │  Service Bus    │    │  VM Scheduler   │
│                 │    │                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │    VMs      │ │    │ │   Topics    │ │    │ │ Logic App   │ │
│ │             │ │    │ │             │ │    │ │             │ │
│ │ - Web Pool  │ │    │ │ Subscript.  │ │    │ │ Function    │ │
│ │ - API Pool  │ │    │ │             │ │    │ │ App         │ │
│ │ - Worker    │ │    │ └─────────────┘ │    │ └─────────────┘ │
│ └─────────────┘ │    └─────────────────┘    └─────────────────┘
└─────────────────┘
```

## Prerequisites

1. **Azure CLI** installed and configured
2. **Terraform** >= 1.7.0
3. **SSH Key Pair** for VM access
4. **Azure Service Principal** with appropriate permissions

## Quick Start

### 1. Setup Azure Authentication

```bash
# Login to Azure
az login

# Create service principal (for CI/CD)
az ad sp create-for-rbac --name "terraform-sp" --role="Contributor" --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID"
```

### 2. Configure Variables

```bash
# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var="pool_type=web" -var="vm_count=2"

# Apply changes
terraform apply -var="pool_type=web" -var="vm_count=2"
```

## Configuration Parameters

| Parameter | Description | Default | Options |
|-----------|-------------|---------|---------|
| `pool_type` | Type of VM pool | `web` | `web`, `api`, `worker` |
| `vm_count` | Number of VMs | `2` | `1-5` |
| `vm_size` | Azure VM size | `Standard_B2s` | Any valid Azure VM size |
| `environment` | Environment name | `dev` | `dev`, `staging`, `prod` |
| `auto_shutdown_enabled` | Enable auto-shutdown | `true` | `true`, `false` |
| `work_hours_start` | Work start time | `09:00` | 24h format |
| `work_hours_end` | Work end time | `18:00` | 24h format |

## VM Scheduling

The infrastructure includes intelligent VM scheduling that automatically:

### Shutdown Conditions
- **Weekends**: Saturday and Sunday
- **Hungarian Holidays**: All official Hungarian public holidays
- **Outside Work Hours**: Before 9 AM and after 6 PM CET
- **Manual Override**: Via Azure Function API

### Hungarian Holidays Included
- New Year's Day (January 1)
- National Day (March 15)
- Good Friday & Easter Monday
- Labour Day (May 1)
- Whit Monday
- St. Stephen's Day (August 20)
- National Day (October 23)
- All Saints' Day (November 1)
- Christmas Day & Boxing Day (December 25-26)

## CI/CD Pipelines

### Azure DevOps Pipeline

```bash
# Trigger with parameters
az pipelines run --name "terraform-pipeline" \
  --parameters pool_type=api vm_count=3 environment=staging action=apply
```

### GitHub Actions

```bash
# Manual trigger via GitHub UI or API
gh workflow run terraform.yml \
  -f pool_type=worker \
  -f vm_count=2 \
  -f environment=prod \
  -f action=apply
```

## Manual VM Control

Use the Azure Function API for manual VM control:

```bash
# Start VMs
curl -X POST "https://vm-scheduler-dev.azurewebsites.net/api/vm/start" \
  -H "Content-Type: application/json" \
  -d '{"vm_names": ["vm-web-1", "vm-web-2"]}'

# Stop VMs
curl -X POST "https://vm-scheduler-dev.azurewebsites.net/api/vm/stop" \
  -H "Content-Type: application/json" \
  -d '{"vm_names": ["vm-web-1", "vm-web-2"]}'

# Get holidays
curl "https://vm-scheduler-dev.azurewebsites.net/api/holidays?year=2024"
```

## Monitoring and Logs

- **VM Status**: Check via Azure Portal or CLI
- **Function Logs**: Available in Azure Application Insights
- **Pipeline Logs**: Available in Azure DevOps/GitHub Actions

## Security Best Practices

1. **SSH Keys**: Only SSH key authentication enabled
2. **Network Security**: NSG rules restrict access
3. **Service Principal**: Minimal required permissions
4. **State Storage**: Encrypted Azure Storage backend
5. **Secrets Management**: Use Azure Key Vault for sensitive data

## Troubleshooting

### Common Issues

1. **SSH Key Not Found**
   ```bash
   # Generate SSH key if missing
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
   ```

2. **Terraform State Lock**
   ```bash
   # Force unlock if needed
   terraform force-unlock LOCK_ID
   ```

3. **VM Scheduling Not Working**
   ```bash
   # Check Function App logs
   az functionapp logs tail --name vm-scheduler-dev --resource-group rg-playground
   ```

## Cost Optimization

- **Auto-shutdown**: Saves ~60% on VM costs
- **B-series VMs**: Burstable performance for cost efficiency  
- **Standard Storage**: Cost-effective for development workloads
- **Resource Tagging**: Track costs by environment and pool type

## Cleanup

```bash
# Destroy all resources
terraform destroy

# Or use pipeline
az pipelines run --name "terraform-pipeline" --parameters action=destroy
```

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review Azure Activity Logs
3. Check Terraform state consistency
4. Verify Azure permissions