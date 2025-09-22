#!/bin/bash
# CI/CD Dashboard Deployment Script for Google Cloud Platform
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
GCP_DIR="$PROJECT_ROOT/gcp"

# Default values
ENVIRONMENT=${ENVIRONMENT:-dev}
GCP_REGION=${GCP_REGION:-us-central1}
GCP_ZONE=${GCP_ZONE:-us-central1-a}
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
    
    # Check if gcloud CLI is installed
    if ! command -v gcloud &> /dev/null; then
        log_error "Google Cloud CLI is not installed. Please install it first."
        log_info "Install: https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check GCP authentication
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 &> /dev/null; then
        log_error "GCP authentication not configured. Please run 'gcloud auth login'."
        exit 1
    fi
    
    # Check if project is set
    local current_project=$(gcloud config get-value project 2>/dev/null)
    if [[ -z "$current_project" ]]; then
        log_error "GCP project not set. Please run 'gcloud config set project YOUR_PROJECT_ID'."
        exit 1
    fi
    
    GCP_PROJECT_ID="$current_project"
    log_info "Using GCP project: $GCP_PROJECT_ID"
    
    # Check if SSH key exists
    if [[ ! -f ~/.ssh/id_rsa.pub ]]; then
        log_warning "No SSH public key found at ~/.ssh/id_rsa.pub"
        log_info "Generating SSH key pair..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    fi
    
    log_success "Prerequisites check completed"
}

enable_required_apis() {
    log_info "Enabling required GCP APIs..."
    
    local apis=(
        "compute.googleapis.com"
        "sqladmin.googleapis.com"
        "monitoring.googleapis.com"
        "logging.googleapis.com"
        "servicenetworking.googleapis.com"
    )
    
    for api in "${apis[@]}"; do
        log_info "Enabling $api..."
        gcloud services enable "$api" --project="$GCP_PROJECT_ID"
    done
    
    log_success "Required APIs enabled"
}

create_terraform_vars() {
    local vars_file="$GCP_DIR/terraform.tfvars"
    
    log_info "Creating Terraform variables file..."
    
    cat > "$vars_file" << EOF
# GCP Infrastructure Configuration
# Generated automatically by deployment script

# Basic Configuration
project_id     = "$GCP_PROJECT_ID"
region         = "$GCP_REGION"
zone           = "$GCP_ZONE"
environment    = "$ENVIRONMENT"
project_name   = "$PROJECT_NAME"
owner          = "$OWNER"

# Network Configuration
public_subnet_cidr  = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"
ssh_source_ranges   = ["0.0.0.0/0"]

# Compute Configuration
machine_type      = "$(get_machine_type)"
instance_count    = $(get_instance_count)
boot_disk_size    = $(get_boot_disk_size)
create_static_ip  = $(get_create_static_ip)

# SSH Configuration
ssh_public_key = "$(cat ~/.ssh/id_rsa.pub)"

# Database Configuration
create_database = true
db_tier         = "$(get_db_tier)"
db_disk_size    = $(get_db_disk_size)
db_name         = "dashboard"
db_username     = "dashboard_user"

# Monitoring Configuration
enable_monitoring = true
enable_logging    = true
EOF

    log_success "Terraform variables file created at $vars_file"
}

get_machine_type() {
    case $ENVIRONMENT in
        prod)    echo "e2-standard-2" ;;
        staging) echo "e2-medium" ;;
        *)       echo "e2-medium" ;;
    esac
}

get_instance_count() {
    case $ENVIRONMENT in
        prod)    echo "3" ;;
        staging) echo "2" ;;
        *)       echo "2" ;;
    esac
}

get_boot_disk_size() {
    case $ENVIRONMENT in
        prod)    echo "50" ;;
        staging) echo "30" ;;
        *)       echo "20" ;;
    esac
}

get_create_static_ip() {
    case $ENVIRONMENT in
        prod)    echo "true" ;;
        *)       echo "false" ;;
    esac
}

get_db_tier() {
    case $ENVIRONMENT in
        prod)    echo "db-n1-standard-1" ;;
        staging) echo "db-f1-micro" ;;
        *)       echo "db-f1-micro" ;;
    esac
}

get_db_disk_size() {
    case $ENVIRONMENT in
        prod)    echo "100" ;;
        staging) echo "50" ;;
        *)       echo "20" ;;
    esac
}

deploy_infrastructure() {
    log_info "Deploying GCP infrastructure..."
    
    cd "$GCP_DIR"
    
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
    
    cd "$GCP_DIR"
    
    local app_url=$(terraform output -raw application_url)
    local lb_ip=$(terraform output -raw load_balancer_ip)
    local project_id=$(terraform output -raw project_id)
    
    echo ""
    log_success "Deployment completed successfully!"
    echo ""
    echo "=========================================="
    echo "         DEPLOYMENT SUMMARY"
    echo "=========================================="
    echo "Environment:      $ENVIRONMENT"
    echo "Project ID:       $project_id"
    echo "Region:           $GCP_REGION"
    echo "Zone:             $GCP_ZONE"
    echo "Application URL:  $app_url"
    echo "Load Balancer IP: $lb_ip"
    echo "=========================================="
    echo ""
    log_info "Frontend will be available at: $app_url"
    log_info "API documentation: $app_url/docs"
    log_info "Health check: $app_url/health"
    echo ""
    log_info "GCP Console: https://console.cloud.google.com/compute/instances?project=$project_id"
    log_info "Monitoring: https://console.cloud.google.com/monitoring?project=$project_id"
    echo ""
    log_warning "Note: Application startup may take 5-10 minutes after infrastructure deployment"
    echo ""
}

cleanup_deployment() {
    log_warning "This will destroy all GCP resources for $PROJECT_NAME-$ENVIRONMENT"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    
    if [[ $confirm == "yes" ]]; then
        cd "$GCP_DIR"
        terraform destroy -auto-approve
        log_success "Infrastructure destroyed"
    else
        log_info "Cleanup cancelled"
    fi
}

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Deploy CI/CD Pipeline Health Dashboard to Google Cloud Platform"
    echo ""
    echo "OPTIONS:"
    echo "  -e, --environment ENV    Environment (dev, staging, prod) [default: dev]"
    echo "  -r, --region REGION      GCP region [default: us-central1]"
    echo "  -z, --zone ZONE          GCP zone [default: us-central1-a]"
    echo "  -p, --project NAME       Project name [default: ci-cd-dashboard]"
    echo "  -o, --owner OWNER        Resource owner [default: devops-team]"
    echo "  -c, --cleanup            Destroy infrastructure"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "EXAMPLES:"
    echo "  $0                                    # Deploy to dev environment"
    echo "  $0 -e prod -r us-west1 -z us-west1-a # Deploy to production in us-west1"
    echo "  $0 --cleanup                         # Destroy infrastructure"
    echo ""
    echo "PREREQUISITES:"
    echo "  1. Install Google Cloud CLI: https://cloud.google.com/sdk/docs/install"
    echo "  2. Authenticate: gcloud auth login"
    echo "  3. Set project: gcloud config set project YOUR_PROJECT_ID"
    echo "  4. Enable billing for your project"
    echo ""
    echo "ENVIRONMENT VARIABLES:"
    echo "  ENVIRONMENT    Environment name"
    echo "  GCP_REGION     GCP region"
    echo "  GCP_ZONE       GCP zone"
    echo "  PROJECT_NAME   Project name"
    echo "  OWNER          Resource owner"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -r|--region)
            GCP_REGION="$2"
            shift 2
            ;;
        -z|--zone)
            GCP_ZONE="$2"
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
    echo "   CI/CD Dashboard GCP Deployment"
    echo "=========================================="
    echo "Environment: $ENVIRONMENT"
    echo "Region:      $GCP_REGION"
    echo "Zone:        $GCP_ZONE"
    echo "Project:     $PROJECT_NAME"
    echo "Owner:       $OWNER"
    echo "=========================================="
    echo ""
    
    if [[ "$CLEANUP" == "true" ]]; then
        cleanup_deployment
        exit 0
    fi
    
    check_prerequisites
    enable_required_apis
    create_terraform_vars
    deploy_infrastructure
    get_outputs
    
    log_success "Deployment completed successfully!"
    log_info "Check the application logs and health status in a few minutes."
}

# Run main function
main
