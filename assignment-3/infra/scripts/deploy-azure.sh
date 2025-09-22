#!/bin/bash
# CI/CD Dashboard Deployment Script for Microsoft Azure
# Generated with AI assistance for streamlined cloud deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
AZURE_DIR="$PROJECT_ROOT/azure"

# Default values
ENVIRONMENT=${ENVIRONMENT:-dev}
AZURE_LOCATION=${AZURE_LOCATION:-"East US"}
PROJECT_NAME=${PROJECT_NAME:-ci-cd-dashboard}
OWNER=${OWNER:-devops-team}

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

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI is not installed. Please install it first."
        log_info "Install: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check Azure authentication
    if ! az account show &> /dev/null; then
        log_error "Azure authentication not configured. Please run 'az login'."
        exit 1
    fi
    
    # Get current subscription
    local subscription_id=$(az account show --query id -o tsv)
    local subscription_name=$(az account show --query name -o tsv)
    log_info "Using Azure subscription: $subscription_name ($subscription_id)"
    
    # Check if SSH key exists
    if [[ ! -f ~/.ssh/id_rsa.pub ]]; then
        log_warning "No SSH public key found at ~/.ssh/id_rsa.pub"
        log_info "Generating SSH key pair..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    fi
    
    log_success "Prerequisites check completed"
}

create_terraform_vars() {
    local vars_file="$AZURE_DIR/terraform.tfvars"
    
    log_info "Creating Terraform variables file..."
    
    cat > "$vars_file" << EOF
# Azure Infrastructure Configuration
# Generated automatically by deployment script

# Basic Configuration
location       = "$AZURE_LOCATION"
environment    = "$ENVIRONMENT"
project_name   = "$PROJECT_NAME"
owner          = "$OWNER"

# Network Configuration
vnet_cidr             = "10.0.0.0/16"
public_subnet_cidr    = "10.0.1.0/24"
private_subnet_cidr   = "10.0.2.0/24"
ssh_source_cidrs      = ["0.0.0.0/0"]

# Compute Configuration
vm_size           = "$(get_vm_size)"
instance_count    = $(get_instance_count)
min_instances     = $(get_min_instances)
max_instances     = $(get_max_instances)

# SSH Configuration
ssh_public_key = "$(cat ~/.ssh/id_rsa.pub)"

# Database Configuration
create_database   = true
db_sku_name       = "$(get_db_sku_name)"
db_storage_mb     = $(get_db_storage_mb)
db_name           = "dashboard"
db_username       = "dashboard_user"

# Monitoring Configuration
enable_monitoring     = true
log_retention_days    = $(get_log_retention_days)
EOF

    log_success "Terraform variables file created at $vars_file"
}

get_vm_size() {
    case $ENVIRONMENT in
        prod)    echo "Standard_D2s_v3" ;;
        staging) echo "Standard_B2s" ;;
        *)       echo "Standard_B2s" ;;
    esac
}

get_instance_count() {
    case $ENVIRONMENT in
        prod)    echo "3" ;;
        staging) echo "2" ;;
        *)       echo "2" ;;
    esac
}

get_min_instances() {
    case $ENVIRONMENT in
        prod)    echo "2" ;;
        staging) echo "1" ;;
        *)       echo "1" ;;
    esac
}

get_max_instances() {
    case $ENVIRONMENT in
        prod)    echo "5" ;;
        staging) echo "3" ;;
        *)       echo "3" ;;
    esac
}

get_db_sku_name() {
    case $ENVIRONMENT in
        prod)    echo "B_Standard_B2s" ;;
        staging) echo "B_Standard_B1ms" ;;
        *)       echo "B_Standard_B1ms" ;;
    esac
}

get_db_storage_mb() {
    case $ENVIRONMENT in
        prod)    echo "131072" ;;  # 128 GB
        staging) echo "65536" ;;   # 64 GB
        *)       echo "32768" ;;   # 32 GB
    esac
}

get_log_retention_days() {
    case $ENVIRONMENT in
        prod)    echo "30" ;;
        staging) echo "14" ;;
        *)       echo "7" ;;
    esac
}

deploy_infrastructure() {
    log_info "Deploying Azure infrastructure..."
    
    cd "$AZURE_DIR"
    
    # Initialize Terraform
    log_info "Initializing Terraform..."
    terraform init
    
    # Plan deployment
    log_info "Creating Terraform plan..."
    terraform plan -out=tfplan
    
    # Apply deployment
    log_info "Applying Terraform configuration..."
    terraform apply tfplan
    
    log_success "Infrastructure deployment completed"
}

get_outputs() {
    log_info "Retrieving deployment outputs..."
    
    cd "$AZURE_DIR"
    
    local app_url=$(terraform output -raw application_url)
    local public_ip=$(terraform output -raw public_ip_address)
    local resource_group=$(terraform output -raw resource_group_name)
    
    echo ""
    log_success "Deployment completed successfully!"
    echo ""
    echo "=========================================="
    echo "         DEPLOYMENT SUMMARY"
    echo "=========================================="
    echo "Environment:       $ENVIRONMENT"
    echo "Location:          $AZURE_LOCATION"
    echo "Resource Group:    $resource_group"
    echo "Application URL:   $app_url"
    echo "Public IP:         $public_ip"
    echo "=========================================="
    echo ""
    log_info "Frontend will be available at: $app_url"
    log_info "API documentation: $app_url/docs"
    log_info "Health check: $app_url/health"
    echo ""
    log_info "Azure Portal: https://portal.azure.com/#@/resource/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$resource_group"
    log_info "VM Scale Set: https://portal.azure.com/#@/resource$(terraform output -raw vm_scale_set_id)"
    log_info "Application Insights: https://portal.azure.com/#@/resource$(terraform output -raw application_insights_name)"
    echo ""
    log_warning "Note: Application startup may take 5-10 minutes after infrastructure deployment"
    echo ""
}

cleanup_deployment() {
    log_warning "This will destroy all Azure resources for $PROJECT_NAME-$ENVIRONMENT"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    
    if [[ $confirm == "yes" ]]; then
        cd "$AZURE_DIR"
        terraform destroy -auto-approve
        log_success "Infrastructure destroyed"
    else
        log_info "Cleanup cancelled"
    fi
}

check_azure_quotas() {
    log_info "Checking Azure quotas and limits..."
    
    local subscription_id=$(az account show --query id -o tsv)
    
    # Check compute quotas
    local cores_quota=$(az vm list-usage --location "$AZURE_LOCATION" --query "[?name.value=='cores'].currentValue" -o tsv 2>/dev/null || echo "0")
    local cores_limit=$(az vm list-usage --location "$AZURE_LOCATION" --query "[?name.value=='cores'].limit" -o tsv 2>/dev/null || echo "unknown")
    
    if [[ "$cores_quota" != "unknown" && "$cores_limit" != "unknown" ]]; then
        log_info "Current vCPU usage: $cores_quota / $cores_limit"
        
        local required_cores=$(get_required_cores)
        local available_cores=$((cores_limit - cores_quota))
        
        if [[ $available_cores -lt $required_cores ]]; then
            log_warning "Insufficient vCPU quota. Required: $required_cores, Available: $available_cores"
            log_info "You may need to request quota increase in Azure Portal"
        fi
    fi
    
    log_success "Quota check completed"
}

get_required_cores() {
    local vm_size=$(get_vm_size)
    local instance_count=$(get_instance_count)
    
    case $vm_size in
        "Standard_B2s")      echo $((2 * instance_count)) ;;
        "Standard_D2s_v3")   echo $((2 * instance_count)) ;;
        *)                   echo $((2 * instance_count)) ;;
    esac
}

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Deploy CI/CD Pipeline Health Dashboard to Microsoft Azure"
    echo ""
    echo "OPTIONS:"
    echo "  -e, --environment ENV    Environment (dev, staging, prod) [default: dev]"
    echo "  -l, --location LOCATION  Azure location [default: East US]"
    echo "  -p, --project NAME       Project name [default: ci-cd-dashboard]"
    echo "  -o, --owner OWNER        Resource owner [default: devops-team]"
    echo "  -c, --cleanup            Destroy infrastructure"
    echo "  -q, --quota-check        Check Azure quotas only"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "EXAMPLES:"
    echo "  $0                                    # Deploy to dev environment"
    echo "  $0 -e prod -l 'West Europe'         # Deploy to production in West Europe"
    echo "  $0 --cleanup                         # Destroy infrastructure"
    echo "  $0 --quota-check                     # Check quotas without deploying"
    echo ""
    echo "PREREQUISITES:"
    echo "  1. Install Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    echo "  2. Authenticate: az login"
    echo "  3. Select subscription: az account set --subscription YOUR_SUBSCRIPTION_ID"
    echo "  4. Ensure sufficient quotas for your chosen location"
    echo ""
    echo "ENVIRONMENT VARIABLES:"
    echo "  ENVIRONMENT      Environment name"
    echo "  AZURE_LOCATION   Azure location"
    echo "  PROJECT_NAME     Project name"
    echo "  OWNER            Resource owner"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -l|--location)
            AZURE_LOCATION="$2"
            shift 2
            ;;
        -p|--project)
            PROJECT_NAME="$2"
            shift 2
            ;;
        -o|--owner)
            OWNER="$2"
            shift 2
            ;;
        -c|--cleanup)
            CLEANUP=true
            shift
            ;;
        -q|--quota-check)
            QUOTA_CHECK=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    log_error "Invalid environment: $ENVIRONMENT. Must be dev, staging, or prod."
    exit 1
fi

# Main execution
main() {
    echo ""
    echo "=========================================="
    echo "   CI/CD Dashboard Azure Deployment"
    echo "=========================================="
    echo "Environment: $ENVIRONMENT"
    echo "Location:    $AZURE_LOCATION"
    echo "Project:     $PROJECT_NAME"
    echo "Owner:       $OWNER"
    echo "=========================================="
    echo ""
    
    if [[ "$QUOTA_CHECK" == "true" ]]; then
        check_prerequisites
        check_azure_quotas
        exit 0
    fi
    
    if [[ "$CLEANUP" == "true" ]]; then
        cleanup_deployment
        exit 0
    fi
    
    check_prerequisites
    check_azure_quotas
    create_terraform_vars
    deploy_infrastructure
    get_outputs
    
    log_success "Deployment completed successfully!"
    log_info "Check the application logs and health status in a few minutes."
}

# Run main function
main
