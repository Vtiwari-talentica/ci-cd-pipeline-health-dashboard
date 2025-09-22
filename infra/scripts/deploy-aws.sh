#!/bin/bash
# CI/CD Dashboard Deployment Script for AWS
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
AWS_DIR="$PROJECT_ROOT/aws"

# Default values
ENVIRONMENT=${ENVIRONMENT:-dev}
AWS_REGION=${AWS_REGION:-us-east-1}
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
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured. Please run 'aws configure'."
        exit 1
    fi
    
    # Check if SSH key exists
    if [[ ! -f ~/.ssh/id_rsa.pub ]]; then
        log_warning "No SSH public key found at ~/.ssh/id_rsa.pub"
        log_info "Generating SSH key pair..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    fi
    
    log_success "Prerequisites check completed"
}

create_terraform_vars() {
    local vars_file="$AWS_DIR/terraform.tfvars"
    
    log_info "Creating Terraform variables file..."
    
    cat > "$vars_file" << EOF
# AWS Infrastructure Configuration
# Generated automatically by deployment script

# Basic Configuration
aws_region     = "$AWS_REGION"
environment    = "$ENVIRONMENT"
project_name   = "$PROJECT_NAME"
owner          = "$OWNER"

# Network Configuration
vpc_cidr                 = "10.0.0.0/16"
availability_zones_count = 2

# Compute Configuration
instance_type     = "$(get_instance_type)"
min_instances     = $(get_min_instances)
max_instances     = $(get_max_instances)
desired_instances = $(get_desired_instances)

# SSH Configuration
public_key        = "$(cat ~/.ssh/id_rsa.pub)"
ssh_cidr_blocks   = ["0.0.0.0/0"]

# Database Configuration
create_database       = true
db_instance_class     = "$(get_db_instance_class)"
db_allocated_storage  = $(get_db_storage)
db_name              = "dashboard"
db_username          = "dashboard_user"
EOF

    log_success "Terraform variables file created at $vars_file"
}

get_instance_type() {
    case $ENVIRONMENT in
        prod)    echo "t3.large" ;;
        staging) echo "t3.medium" ;;
        *)       echo "t3.medium" ;;
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

get_desired_instances() {
    case $ENVIRONMENT in
        prod)    echo "3" ;;
        staging) echo "2" ;;
        *)       echo "2" ;;
    esac
}

get_db_instance_class() {
    case $ENVIRONMENT in
        prod)    echo "db.t3.small" ;;
        staging) echo "db.t3.micro" ;;
        *)       echo "db.t3.micro" ;;
    esac
}

get_db_storage() {
    case $ENVIRONMENT in
        prod)    echo "100" ;;
        staging) echo "50" ;;
        *)       echo "20" ;;
    esac
}

deploy_infrastructure() {
    log_info "Deploying AWS infrastructure..."
    
    cd "$AWS_DIR"
    
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
    
    cd "$AWS_DIR"
    
    local app_url=$(terraform output -raw application_url)
    local db_endpoint=$(terraform output -raw database_endpoint)
    local lb_dns=$(terraform output -raw load_balancer_dns)
    
    echo ""
    log_success "Deployment completed successfully!"
    echo ""
    echo "=========================================="
    echo "         DEPLOYMENT SUMMARY"
    echo "=========================================="
    echo "Environment:      $ENVIRONMENT"
    echo "Region:           $AWS_REGION"
    echo "Application URL:  $app_url"
    echo "Load Balancer:    $lb_dns"
    echo "Database:         $db_endpoint"
    echo "=========================================="
    echo ""
    log_info "Frontend will be available at: $app_url"
    log_info "API documentation: $app_url/docs"
    log_info "Health check: $app_url/health"
    echo ""
    log_warning "Note: Application startup may take 5-10 minutes after infrastructure deployment"
    echo ""
}

cleanup_deployment() {
    log_warning "This will destroy all AWS resources for $PROJECT_NAME-$ENVIRONMENT"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    
    if [[ $confirm == "yes" ]]; then
        cd "$AWS_DIR"
        terraform destroy -auto-approve
        log_success "Infrastructure destroyed"
    else
        log_info "Cleanup cancelled"
    fi
}

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Deploy CI/CD Pipeline Health Dashboard to AWS"
    echo ""
    echo "OPTIONS:"
    echo "  -e, --environment ENV    Environment (dev, staging, prod) [default: dev]"
    echo "  -r, --region REGION      AWS region [default: us-east-1]"
    echo "  -p, --project NAME       Project name [default: ci-cd-dashboard]"
    echo "  -o, --owner OWNER        Resource owner [default: devops-team]"
    echo "  -c, --cleanup            Destroy infrastructure"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "EXAMPLES:"
    echo "  $0                                    # Deploy to dev environment"
    echo "  $0 -e prod -r us-west-2             # Deploy to production in us-west-2"
    echo "  $0 --cleanup                         # Destroy infrastructure"
    echo ""
    echo "ENVIRONMENT VARIABLES:"
    echo "  ENVIRONMENT    Environment name"
    echo "  AWS_REGION     AWS region"
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
            AWS_REGION="$2"
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
    echo "   CI/CD Dashboard AWS Deployment"
    echo "=========================================="
    echo "Environment: $ENVIRONMENT"
    echo "Region:      $AWS_REGION"
    echo "Project:     $PROJECT_NAME"
    echo "Owner:       $OWNER"
    echo "=========================================="
    echo ""
    
    if [[ "$CLEANUP" == "true" ]]; then
        cleanup_deployment
        exit 0
    fi
    
    check_prerequisites
    create_terraform_vars
    deploy_infrastructure
    get_outputs
    
    log_success "Deployment completed successfully!"
    log_info "Check the application logs and health status in a few minutes."
}

# Run main function
main
