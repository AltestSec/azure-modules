#!/bin/bash

# Azure Playground Deployment Script
# Usage: ./deploy.sh [plan|apply|destroy] [pool_type] [vm_count] [environment]

set -e

# Default values
ACTION=${1:-plan}
POOL_TYPE=${2:-web}
VM_COUNT=${3:-2}
ENVIRONMENT=${4:-dev}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Validate inputs
validate_inputs() {
    if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
        log_error "Invalid action: $ACTION. Use: plan, apply, or destroy"
        exit 1
    fi

    if [[ ! "$POOL_TYPE" =~ ^(web|api|worker)$ ]]; then
        log_error "Invalid pool type: $POOL_TYPE. Use: web, api, or worker"
        exit 1
    fi

    if [[ ! "$VM_COUNT" =~ ^[1-5]$ ]]; then
        log_error "Invalid VM count: $VM_COUNT. Use: 1-5"
        exit 1
    fi

    if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
        log_error "Invalid environment: $ENVIRONMENT. Use: dev, staging, or prod"
        exit 1
    fi
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

    # Check if logged into Azure
    if ! az account show &> /dev/null; then
        log_error "Not logged into Azure. Please run 'az login' first."
        exit 1
    fi

    # Check if SSH key exists
    if [[ ! -f ~/.ssh/id_rsa.pub ]]; then
        log_warning "SSH public key not found at ~/.ssh/id_rsa.pub"
        read -p "Generate SSH key pair? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
            log_success "SSH key pair generated"
        else
            log_error "SSH key required for VM access"
            exit 1
        fi
    fi

    # Check if terraform.tfvars exists
    if [[ ! -f terraform.tfvars ]]; then
        log_warning "terraform.tfvars not found"
        if [[ -f terraform.tfvars.example ]]; then
            log_info "Copying terraform.tfvars.example to terraform.tfvars"
            cp terraform.tfvars.example terraform.tfvars
            log_warning "Please edit terraform.tfvars with your Azure subscription and tenant IDs"
            read -p "Press Enter to continue after editing terraform.tfvars..."
        else
            log_error "terraform.tfvars.example not found"
            exit 1
        fi
    fi

    log_success "Prerequisites check completed"
}

# Setup Terraform backend
setup_backend() {
    log_info "Setting up Terraform backend..."

    # Get current subscription ID
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    
    # Create resource group for Terraform state
    az group create --name tfstate-rg --location "West Europe" --output none || true
    
    # Generate unique storage account name
    STORAGE_NAME="tfstate$(date +%s | tail -c 6)"
    
    # Create storage account
    az storage account create \
        --name $STORAGE_NAME \
        --resource-group tfstate-rg \
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
        -backend-config="resource_group_name=tfstate-rg" \
        -reconfigure
}

# Deploy infrastructure
deploy() {
    log_info "Starting deployment with parameters:"
    log_info "  Action: $ACTION"
    log_info "  Pool Type: $POOL_TYPE"
    log_info "  VM Count: $VM_COUNT"
    log_info "  Environment: $ENVIRONMENT"

    case $ACTION in
        plan)
            log_info "Running Terraform plan..."
            terraform plan \
                -var="pool_type=$POOL_TYPE" \
                -var="vm_count=$VM_COUNT" \
                -var="environment=$ENVIRONMENT" \
                -out=tfplan
            log_success "Terraform plan completed. Review the plan above."
            ;;
        apply)
            log_info "Running Terraform apply..."
            terraform plan \
                -var="pool_type=$POOL_TYPE" \
                -var="vm_count=$VM_COUNT" \
                -var="environment=$ENVIRONMENT" \
                -out=tfplan
            
            echo
            log_warning "About to apply the above plan. This will create/modify Azure resources."
            read -p "Continue? (y/n): " -n 1 -r
            echo
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                terraform apply tfplan
                log_success "Infrastructure deployed successfully!"
                
                # Show outputs
                log_info "Infrastructure details:"
                terraform output
                
                # Deploy VM scheduler function
                deploy_scheduler
            else
                log_info "Deployment cancelled"
            fi
            ;;
        destroy)
            log_warning "This will destroy ALL infrastructure resources!"
            read -p "Are you sure? Type 'yes' to confirm: " -r
            
            if [[ $REPLY == "yes" ]]; then
                terraform destroy \
                    -var="pool_type=$POOL_TYPE" \
                    -var="vm_count=$VM_COUNT" \
                    -var="environment=$ENVIRONMENT" \
                    -auto-approve
                log_success "Infrastructure destroyed"
            else
                log_info "Destroy cancelled"
            fi
            ;;
    esac
}

# Deploy VM scheduler function
deploy_scheduler() {
    log_info "Deploying VM scheduler function..."
    
    RG_NAME=$(terraform output -raw resource_group_name)
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    
    # Create Function App
    FUNC_APP_NAME="vm-scheduler-$ENVIRONMENT"
    STORAGE_NAME="vmscheduler$(date +%s | tail -c 6)"
    
    # Create storage account for function app
    az storage account create \
        --name $STORAGE_NAME \
        --resource-group $RG_NAME \
        --location "West Europe" \
        --sku Standard_LRS \
        --output none
    
    # Create function app
    az functionapp create \
        --resource-group $RG_NAME \
        --consumption-plan-location "West Europe" \
        --runtime python \
        --runtime-version 3.9 \
        --functions-version 4 \
        --name $FUNC_APP_NAME \
        --storage-account $STORAGE_NAME \
        --output none
    
    # Set environment variables
    az functionapp config appsettings set \
        --name $FUNC_APP_NAME \
        --resource-group $RG_NAME \
        --settings \
        "AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID" \
        "RESOURCE_GROUP_NAME=$RG_NAME" \
        "POOL_TYPE=$POOL_TYPE" \
        "VM_COUNT=$VM_COUNT" \
        --output none
    
    log_success "VM scheduler function app created: $FUNC_APP_NAME"
    log_info "Deploy the function code from vm-scheduler-function/ directory"
}

# Main execution
main() {
    echo "=================================="
    echo "Azure Playground Deployment Script"
    echo "=================================="
    echo

    validate_inputs
    check_prerequisites
    setup_backend
    deploy

    echo
    log_success "Deployment script completed!"
}

# Run main function
main "$@"