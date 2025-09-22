# 🚀 CI/CD Pipeline Health Dashboard - Cloud Deployment Guide

## Overview

This guide provides comprehensive instructions for deploying the CI/CD Pipeline Health Dashboard to AWS, Google Cloud Platform (GCP), or Microsoft Azure using Infrastructure-as-Code (IaC) with Terraform.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Platform-Specific Deployment](#platform-specific-deployment)
  - [AWS Deployment](#aws-deployment)
  - [GCP Deployment](#gcp-deployment)
  - [Azure Deployment](#azure-deployment)
- [Environment Configuration](#environment-configuration)
- [Post-Deployment](#post-deployment)
- [Monitoring & Maintenance](#monitoring--maintenance)
- [Troubleshooting](#troubleshooting)
- [Cost Optimization](#cost-optimization)

## Prerequisites

### Required Tools

1. **Terraform** (>= 1.0)
   ```bash
   # Install via Homebrew (macOS)
   brew install terraform
   
   # Or download from: https://www.terraform.io/downloads
   ```

2. **Git**
   ```bash
   git --version  # Verify installation
   ```

3. **Cloud CLI Tools** (choose your platform):
   - **AWS CLI**: https://aws.amazon.com/cli/
   - **Google Cloud CLI**: https://cloud.google.com/sdk/docs/install
   - **Azure CLI**: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

### Cloud Account Setup

#### AWS Prerequisites
- AWS account with billing enabled
- IAM user with appropriate permissions
- AWS CLI configured: `aws configure`

#### GCP Prerequisites
- Google Cloud project with billing enabled
- Service account with necessary permissions
- gcloud CLI authenticated: `gcloud auth login`

#### Azure Prerequisites
- Azure subscription with sufficient quotas
- Azure CLI authenticated: `az login`

## Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/your-username/ci-cd-pipeline-health-dashboard.git
cd ci-cd-pipeline-health-dashboard/infra
```

### 2. Choose Your Cloud Platform
```bash
# AWS
./scripts/deploy-aws.sh

# GCP  
./scripts/deploy-gcp.sh

# Azure
./scripts/deploy-azure.sh
```

### 3. Access Your Application
After deployment completes (5-10 minutes), access your dashboard at the provided URL.

## Platform-Specific Deployment

## AWS Deployment

### Architecture
- **Compute**: EC2 instances with Auto Scaling Groups
- **Load Balancer**: Application Load Balancer (ALB)
- **Database**: RDS PostgreSQL
- **Networking**: VPC with public/private subnets
- **Security**: Security Groups, Key Pairs

### Deployment Steps

1. **Configure AWS Credentials**
   ```bash
   aws configure
   # Enter: Access Key ID, Secret Access Key, Region, Output format
   ```

2. **Deploy Infrastructure**
   ```bash
   cd infra
   chmod +x scripts/deploy-aws.sh
   
   # Deploy to development environment
   ./scripts/deploy-aws.sh
   
   # Deploy to production in us-west-2
   ./scripts/deploy-aws.sh -e prod -r us-west-2
   ```

3. **Verify Deployment**
   ```bash
   # Check infrastructure status
   cd aws
   terraform show
   
   # Check application health
   curl -f "$(terraform output -raw application_url)/health"
   ```

### AWS Configuration Options

| Environment | Instance Type | RDS Class | Min/Max Instances | Storage |
|-------------|---------------|-----------|-------------------|---------|
| dev         | t3.medium     | db.t3.micro | 1/3             | 20 GB   |
| staging     | t3.medium     | db.t3.micro | 1/3             | 50 GB   |
| prod        | t3.large      | db.t3.small | 2/5             | 100 GB  |

### AWS Cleanup
```bash
./scripts/deploy-aws.sh --cleanup
```

## GCP Deployment

### Architecture
- **Compute**: Compute Engine with Managed Instance Groups
- **Load Balancer**: Global HTTP(S) Load Balancer
- **Database**: Cloud SQL PostgreSQL
- **Networking**: VPC with Cloud NAT
- **Security**: Firewall Rules, IAM Service Accounts

### Deployment Steps

1. **Set Up GCP Project**
   ```bash
   # Authenticate
   gcloud auth login
   
   # Set project
   gcloud config set project YOUR_PROJECT_ID
   
   # Enable billing (if not already enabled)
   gcloud alpha billing projects link YOUR_PROJECT_ID --billing-account=YOUR_BILLING_ACCOUNT
   ```

2. **Deploy Infrastructure**
   ```bash
   cd infra
   chmod +x scripts/deploy-gcp.sh
   
   # Deploy to development environment
   ./scripts/deploy-gcp.sh
   
   # Deploy to production in us-west1
   ./scripts/deploy-gcp.sh -e prod -r us-west1 -z us-west1-a
   ```

3. **Verify Deployment**
   ```bash
   # Check infrastructure status
   cd gcp
   terraform show
   
   # Check application health
   curl -f "$(terraform output -raw application_url)/health"
   ```

### GCP Configuration Options

| Environment | Machine Type | DB Tier | Instance Count | Disk Size |
|-------------|--------------|---------|----------------|-----------|
| dev         | e2-medium    | db-f1-micro | 2          | 20 GB     |
| staging     | e2-medium    | db-f1-micro | 2          | 30 GB     |
| prod        | e2-standard-2| db-n1-standard-1 | 3      | 50 GB     |

### GCP Cleanup
```bash
./scripts/deploy-gcp.sh --cleanup
```

## Azure Deployment

### Architecture
- **Compute**: Virtual Machine Scale Sets
- **Load Balancer**: Azure Load Balancer
- **Database**: PostgreSQL Flexible Server
- **Networking**: Virtual Network with subnets
- **Security**: Network Security Groups, Key Vault

### Deployment Steps

1. **Set Up Azure Subscription**
   ```bash
   # Authenticate
   az login
   
   # List subscriptions
   az account list --output table
   
   # Set active subscription
   az account set --subscription "YOUR_SUBSCRIPTION_ID"
   ```

2. **Check Quotas**
   ```bash
   cd infra
   chmod +x scripts/deploy-azure.sh
   
   # Check quotas before deployment
   ./scripts/deploy-azure.sh --quota-check
   ```

3. **Deploy Infrastructure**
   ```bash
   # Deploy to development environment
   ./scripts/deploy-azure.sh
   
   # Deploy to production in West Europe
   ./scripts/deploy-azure.sh -e prod -l "West Europe"
   ```

4. **Verify Deployment**
   ```bash
   # Check infrastructure status
   cd azure
   terraform show
   
   # Check application health
   curl -f "$(terraform output -raw application_url)/health"
   ```

### Azure Configuration Options

| Environment | VM Size | DB SKU | Min/Max Instances | Storage |
|-------------|---------|---------|-------------------|---------|
| dev         | Standard_B2s | B_Standard_B1ms | 1/3 | 32 GB |
| staging     | Standard_B2s | B_Standard_B1ms | 1/3 | 64 GB |
| prod        | Standard_D2s_v3 | B_Standard_B2s | 2/5 | 128 GB |

### Azure Cleanup
```bash
./scripts/deploy-azure.sh --cleanup
```

## Environment Configuration

### Environment Variables

All deployment scripts support environment variables:

```bash
# Set environment variables
export ENVIRONMENT=staging
export PROJECT_NAME=my-dashboard
export OWNER=my-team

# AWS specific
export AWS_REGION=us-west-2

# GCP specific
export GCP_REGION=us-central1
export GCP_ZONE=us-central1-a

# Azure specific
export AZURE_LOCATION="West US 2"

# Deploy with environment variables
./scripts/deploy-aws.sh
```

### Custom Configuration

For advanced customization, edit the Terraform variables files:

```bash
# AWS
vi aws/terraform.tfvars

# GCP
vi gcp/terraform.tfvars

# Azure
vi azure/terraform.tfvars
```

## Post-Deployment

### 1. Application Configuration

After infrastructure deployment, configure your application:

1. **SSH into instances** (if needed):
   ```bash
   # AWS
   ssh -i ~/.ssh/id_rsa ubuntu@<instance-ip>
   
   # GCP
   gcloud compute ssh ubuntu@<instance-name> --zone=<zone>
   
   # Azure
   ssh -i ~/.ssh/id_rsa azureuser@<instance-ip>
   ```

2. **Update environment variables**:
   ```bash
   sudo vi /opt/ci-cd-dashboard/.env
   
   # Update GitHub and Jenkins credentials
   GITHUB_TOKEN=your_token_here
   JENKINS_URL=https://your-jenkins.com
   JENKINS_USER=your_user
   JENKINS_TOKEN=your_token
   
   # Restart application
   sudo systemctl restart ci-cd-dashboard
   ```

### 2. SSL/TLS Configuration

For production deployments, configure HTTPS:

#### AWS (with Certificate Manager)
```bash
# Request certificate
aws acm request-certificate --domain-name yourdomain.com --validation-method DNS

# Update ALB listener to use HTTPS
```

#### GCP (with Managed SSL)
```bash
# Create managed SSL certificate
gcloud compute ssl-certificates create dashboard-ssl --domains=yourdomain.com
```

#### Azure (with App Gateway)
```bash
# Create and configure Application Gateway with SSL termination
```

### 3. DNS Configuration

Point your domain to the load balancer:

- **AWS**: Use Route 53 or your DNS provider to point to ALB DNS name
- **GCP**: Point to Global Load Balancer IP
- **Azure**: Point to Load Balancer public IP

## Monitoring & Maintenance

### Health Checks

Monitor application health:

```bash
# Check application status
curl -f "https://your-domain.com/health"

# Check API documentation
curl -f "https://your-domain.com/docs"
```

### Log Monitoring

#### AWS CloudWatch
```bash
# View logs
aws logs describe-log-groups --log-group-name-prefix "/aws/ec2/ci-cd-dashboard"
```

#### GCP Cloud Logging
```bash
# View logs
gcloud logging read "resource.type=gce_instance" --limit=50
```

#### Azure Monitor
```bash
# View logs via Azure CLI
az monitor log-analytics query --workspace <workspace-id> --analytics-query "requests | limit 50"
```

### Scaling

All deployments include auto-scaling based on CPU utilization:
- **Scale Out**: CPU > 75% for 5 minutes
- **Scale In**: CPU < 25% for 5 minutes

Manual scaling:

```bash
# AWS
aws autoscaling set-desired-capacity --auto-scaling-group-name <asg-name> --desired-capacity 3

# GCP
gcloud compute instance-groups managed resize <instance-group> --size 3 --region <region>

# Azure
az vmss scale --resource-group <rg-name> --name <vmss-name> --new-capacity 3
```

## Troubleshooting

### Common Issues

#### 1. Deployment Fails
```bash
# Check Terraform state
terraform show
terraform refresh

# Debug with detailed logging
export TF_LOG=DEBUG
terraform apply
```

#### 2. Application Not Accessible
```bash
# Check security groups/firewall rules
# Verify load balancer health checks
# Check application logs on instances

# AWS
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# GCP
gcloud compute backend-services get-health <backend-service>

# Azure
az network lb probe list --resource-group <rg> --lb-name <lb-name>
```

#### 3. Database Connection Issues
```bash
# Check security group rules for database port (5432)
# Verify database credentials in application configuration
# Test database connectivity from application instances

# Test connection
telnet <db-endpoint> 5432
```

#### 4. SSL Certificate Issues
```bash
# Check certificate status
# AWS
aws acm describe-certificate --certificate-arn <cert-arn>

# GCP
gcloud compute ssl-certificates describe <cert-name>

# Azure
az network application-gateway ssl-cert show --gateway-name <gw-name> --resource-group <rg> --name <cert-name>
```

### Debug Commands

```bash
# Check cloud-init logs
sudo tail -f /var/log/cloud-init-output.log

# Check application logs
sudo journalctl -u ci-cd-dashboard.service -f

# Check Docker containers
docker-compose ps
docker-compose logs

# Run health check script
sudo /opt/ci-cd-dashboard/health-check.sh
```

## Cost Optimization

### Development Environment
- Use burstable instances (t3.micro, e2-micro, B1s)
- Single AZ deployment
- Smaller databases
- Scheduled shutdown outside business hours

### Production Environment
- Reserved instances for predictable workloads
- Spot instances for development/testing
- Regular monitoring and right-sizing
- Automated scaling policies

### Cost Monitoring

```bash
# AWS
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity MONTHLY --metrics BlendedCost

# GCP
gcloud billing accounts list
gcloud alpha billing projects describe <project-id>

# Azure
az consumption usage list --start-date 2024-01-01 --end-date 2024-01-31
```

## Security Best Practices

1. **Network Security**
   - Use private subnets for databases
   - Restrict SSH access to specific IP ranges
   - Enable VPC Flow Logs

2. **Access Control**
   - Use IAM roles instead of access keys
   - Implement least privilege principle
   - Enable MFA for admin accounts

3. **Data Protection**
   - Enable encryption at rest and in transit
   - Regular database backups
   - Secrets management (AWS Secrets Manager, GCP Secret Manager, Azure Key Vault)

4. **Monitoring**
   - Enable CloudTrail/Cloud Audit Logs
   - Set up security alerts
   - Regular security assessments

## Support & Documentation

- **Terraform AWS Provider**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **Terraform GCP Provider**: https://registry.terraform.io/providers/hashicorp/google/latest/docs
- **Terraform Azure Provider**: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- **Project Repository**: https://github.com/your-username/ci-cd-pipeline-health-dashboard

For additional support, please open an issue in the project repository.
