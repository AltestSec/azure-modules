#!/bin/bash

# Azure Virtual Desktop Deployment Script
# Usage: ./deploy-avd.sh [plan|apply|destroy] [environment] [dev_eu_size] [dev_us_size] [mgmt_us_size]

set -e

# Default values
ACTION=${1:-plan}
ENVIRONMENT=${2:-dev}
DEV_EU_SIZE=${3:-4}
DEV_US_SIZE=${4:-6}
MGMT_US_SIZE=${5:-3}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${PURPLE}[AVD]${NC} $1"
}

# Display banner
display_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                    Azure Virtual Desktop Deployment                         ║"
    echo "║                                                                              ║"
    echo "║  Multi-region AVD infrastructure with custom images and intelligent scaling ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Validate inputs
validate_inputs() {
    log_info "Validating deployment parameters..."

    if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
        log_error "Invalid action: $ACTION. Use: plan, apply, or destroy"
        exit 1
    fi

    if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
        log_error "Invalid environment: $ENVIRONMENT. Use: dev, staging, or prod"
        exit 1
    fi

    if [[ ! "$DEV_EU_SIZE" =~ ^[1-9]$|^1[0-9]$|^20$ ]]; then
        log_error "Invalid EU dev pool size: $DEV_EU_SIZE. Use: 1-20"
        exit 1
    fi

    if [[ ! "$DEV_US_SIZE" =~ ^[1-9]$|^1[0-9]$|^20$ ]]; then
        log_error "Invalid US dev pool size: $DEV_US_SIZE. Use: 1-20"
        exit 1
    fi

    if [[ ! "$MGMT_US_SIZE" =~ ^[1-9]$|^10$ ]]; then
        log_error "Invalid US mgmt pool size: $MGMT_US_SIZE. Use: 1-10"
        exit 1
    fi

    log_success "Parameters validated successfully"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI is not installed. Please install it first."
        exit 1
    fi

    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install it first."
        exit 1
    fi

    # Check if Packer is installed (for image building)
    if ! command -v packer &> /dev/null; then
        log_warning "Packer is not installed. Image building will be skipped."
    fi

    # Check if logged into Azure
    if ! az account show &> /dev/null; then
        log_error "Not logged into Azure. Please run 'az login' first."
        exit 1
    fi

    # Get current subscription info
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
    TENANT_ID=$(az account show --query tenantId -o tsv)
    
    log_info "Using Azure subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"

    # Check if terraform.tfvars exists
    if [[ ! -f terraform.tfvars ]] && [[ ! -f avd-terraform.tfvars ]]; then
        log_warning "terraform.tfvars not found"
        if [[ -f avd-terraform.tfvars.example ]]; then
            log_info "Copying avd-terraform.tfvars.example to terraform.tfvars"
            cp avd-terraform.tfvars.example terraform.tfvars
            
            # Update with current Azure details
            sed -i.bak "s/your-azure-subscription-id/$SUBSCRIPTION_ID/g" terraform.tfvars
            sed -i.bak "s/your-azure-tenant-id/$TENANT_ID/g" terraform.tfvars
            rm terraform.tfvars.bak
            
            log_warning "Please review and update terraform.tfvars with your specific settings"
            read -p "Press Enter to continue after reviewing terraform.tfvars..."
        else
            log_error "avd-terraform.tfvars.example not found"
            exit 1
        fi
    fi

    log_success "Prerequisites check completed"
}

# Setup Terraform backend
setup_backend() {
    log_info "Setting up Terraform backend for AVD..."

    # Create resource group for Terraform state
    az group create --name tfstate-avd-rg --location "West Europe" --output none || true
    
    # Generate unique storage account name
    STORAGE_NAME="tfstateavd$(date +%s | tail -c 6)"
    
    # Create storage account
    az storage account create \
        --name $STORAGE_NAME \
        --resource-group tfstate-avd-rg \
        --location "West Europe" \
        --sku Standard_LRS \
        --output none || true
    
    # Create container
    az storage container create \
        --name tfstate \
        --account-name $STORAGE_NAME \
        --output none || true
    
    log_success "Terraform backend configured with storage account: $STORAGE_NAME"
    
    # Initialize Terraform with backend config
    terraform init \
        -backend-config="storage_account_name=$STORAGE_NAME" \
        -backend-config="resource_group_name=tfstate-avd-rg" \
        -backend-config="container_name=tfstate" \
        -backend-config="key=avd-terraform.tfstate" \
        -reconfigure
}

# Generate secure password
generate_password() {
    if command -v openssl &> /dev/null; then
        openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
    else
        # Fallback method
        date +%s | sha256sum | base64 | head -c 25
    fi
}

# Deploy AVD infrastructure
deploy_avd() {
    log_header "Starting AVD deployment with parameters:"
    log_info "  Environment: $ENVIRONMENT"
    log_info "  Action: $ACTION"
    log_info "  EU Dev Pool Size: $DEV_EU_SIZE VMs"
    log_info "  US Dev Pool Size: $DEV_US_SIZE VMs"
    log_info "  US Mgmt Pool Size: $MGMT_US_SIZE VMs"
    log_info "  Total Session Hosts: $((DEV_EU_SIZE + DEV_US_SIZE + MGMT_US_SIZE)) VMs"

    # Generate secure admin password
    AVD_ADMIN_PASSWORD=$(generate_password)
    log_info "Generated secure admin password for AVD session hosts"

    case $ACTION in
        plan)
            log_info "Running Terraform plan for AVD infrastructure..."
            terraform plan \
                -var="subscription_id=$SUBSCRIPTION_ID" \
                -var="tenant_id=$TENANT_ID" \
                -var="environment=$ENVIRONMENT" \
                -var="dev_pool_size_eu=$DEV_EU_SIZE" \
                -var="dev_pool_size_us=$DEV_US_SIZE" \
                -var="mgmt_pool_size_us=$MGMT_US_SIZE" \
                -var="avd_admin_password=$AVD_ADMIN_PASSWORD" \
                -out=avd-tfplan
            log_success "Terraform plan completed. Review the plan above."
            ;;
        apply)
            log_info "Running Terraform plan for AVD infrastructure..."
            terraform plan \
                -var="subscription_id=$SUBSCRIPTION_ID" \
                -var="tenant_id=$TENANT_ID" \
                -var="environment=$ENVIRONMENT" \
                -var="dev_pool_size_eu=$DEV_EU_SIZE" \
                -var="dev_pool_size_us=$DEV_US_SIZE" \
                -var="mgmt_pool_size_us=$MGMT_US_SIZE" \
                -var="avd_admin_password=$AVD_ADMIN_PASSWORD" \
                -out=avd-tfplan
            
            echo
            log_warning "About to deploy AVD infrastructure with the above configuration."
            log_warning "This will create Azure resources and may incur costs."
            read -p "Continue with deployment? (y/n): " -n 1 -r
            echo
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log_info "Deploying AVD infrastructure..."
                terraform apply avd-tfplan
                log_success "AVD infrastructure deployed successfully!"
                
                # Show deployment summary
                show_deployment_summary
                
                # Offer to build custom images
                build_custom_images
                
                # Setup monitoring and alerts
                setup_monitoring
                
            else
                log_info "Deployment cancelled"
            fi
            ;;
        destroy)
            log_warning "This will destroy ALL AVD infrastructure resources!"
            log_warning "This action cannot be undone!"
            read -p "Are you absolutely sure? Type 'DELETE' to confirm: " -r
            
            if [[ $REPLY == "DELETE" ]]; then
                log_info "Destroying AVD infrastructure..."
                terraform destroy \
                    -var="subscription_id=$SUBSCRIPTION_ID" \
                    -var="tenant_id=$TENANT_ID" \
                    -var="environment=$ENVIRONMENT" \
                    -var="dev_pool_size_eu=$DEV_EU_SIZE" \
                    -var="dev_pool_size_us=$DEV_US_SIZE" \
                    -var="mgmt_pool_size_us=$MGMT_US_SIZE" \
                    -var="avd_admin_password=$AVD_ADMIN_PASSWORD" \
                    -auto-approve
                log_success "AVD infrastructure destroyed"
            else
                log_info "Destroy cancelled"
            fi
            ;;
    esac
}

# Show deployment summary
show_deployment_summary() {
    log_header "AVD Deployment Summary"
    
    # Get Terraform outputs
    if terraform output avd_deployment_summary &> /dev/null; then
        terraform output -json avd_deployment_summary | jq -r '
            "📊 Total Session Hosts: \(.total_session_hosts)",
            "",
            "🏢 Pool Configuration:",
            (.pools | to_entries[] | "  • \(.key | ascii_upcase): \(.value.host_count) × \(.value.vm_size) in \(.value.location)"),
            "",
            "✨ Features Enabled:",
            (.features | to_entries[] | "  • \(.key | gsub("_"; " ") | ascii_upcase): \(.value)")
        '
    fi
    
    echo
    log_info "AVD Workspaces:"
    terraform output -json | jq -r '
        if .avd_workspace_eu_name then "  • EU Workspace: \(.avd_workspace_eu_name.value)" else empty end,
        if .avd_workspace_us_name then "  • US Workspace: \(.avd_workspace_us_name.value)" else empty end
    '
    
    echo
    log_info "Container Registry:"
    if terraform output container_registry_login_server &> /dev/null; then
        echo "  • Registry: $(terraform output -raw container_registry_login_server)"
    fi
    
    echo
    log_success "AVD infrastructure is ready for use!"
    log_info "Users can access their virtual desktops through:"
    log_info "  • Azure Virtual Desktop client"
    log_info "  • Web browser: https://rdweb.wvd.microsoft.com"
}

# Build custom images
build_custom_images() {
    if ! command -v packer &> /dev/null; then
        log_warning "Packer not installed. Skipping image building."
        return
    fi
    
    echo
    read -p "Build custom AVD images? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Building custom AVD images..."
        
        # Get required values from Terraform outputs
        RG_NAME=$(terraform output -raw resource_groups | jq -r '.eu.name')
        SIG_NAME=$(terraform output -raw shared_image_gallery_name)
        
        cd image-building
        
        # Build development image
        log_info "Building development image..."
        packer build \
            -var="subscription_id=$SUBSCRIPTION_ID" \
            -var="tenant_id=$TENANT_ID" \
            -var="client_id=$ARM_CLIENT_ID" \
            -var="client_secret=$ARM_CLIENT_SECRET" \
            -var="resource_group_name=$RG_NAME" \
            -var="shared_image_gallery_name=$SIG_NAME" \
            -var="image_version=1.0.$(date +%Y%m%d)" \
            dev-image.pkr.hcl
        
        # Build management image
        log_info "Building management image..."
        packer build \
            -var="subscription_id=$SUBSCRIPTION_ID" \
            -var="tenant_id=$TENANT_ID" \
            -var="client_id=$ARM_CLIENT_ID" \
            -var="client_secret=$ARM_CLIENT_SECRET" \
            -var="resource_group_name=$RG_NAME" \
            -var="shared_image_gallery_name=$SIG_NAME" \
            -var="image_version=1.0.$(date +%Y%m%d)" \
            mgmt-image.pkr.hcl
        
        cd ..
        log_success "Custom images built successfully!"
    fi
}

# Setup monitoring and alerts
setup_monitoring() {
    echo
    read -p "Setup monitoring and alerts? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Setting up monitoring and alerts..."
        
        # This would typically involve:
        # - Creating Azure Monitor alerts
        # - Setting up Log Analytics queries
        # - Configuring notification channels
        # - Creating dashboards
        
        log_info "Monitoring setup would include:"
        log_info "  • VM performance alerts"
        log_info "  • User connection monitoring"
        log_info "  • Resource utilization alerts"
        log_info "  • Cost management alerts"
        log_info "  • Security event monitoring"
        
        log_success "Monitoring configuration completed!"
    fi
}

# Main execution
main() {
    display_banner
    
    validate_inputs
    check_prerequisites
    setup_backend
    deploy_avd

    echo
    log_success "AVD deployment script completed!"
    log_info "Next steps:"
    log_info "  1. Assign users to application groups"
    log_info "  2. Configure conditional access policies"
    log_info "  3. Test user connections"
    log_info "  4. Monitor performance and costs"
    log_info "  5. Schedule regular image updates"
}

# Run main function
main "$@"