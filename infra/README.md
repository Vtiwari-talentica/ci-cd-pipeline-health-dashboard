# Infrastructure as Code (IaC) for CI/CD Pipeline Health Dashboard

This directory contains Terraform scripts and infrastructure provisioning code for deploying the CI/CD Pipeline Health Dashboard to major cloud platforms.

## Directory Structure

```
infra/
├── README.md                    # This file - IaC overview and usage
├── aws/                         # AWS-specific Terraform configurations
│   ├── main.tf                  # Main AWS infrastructure definition
│   ├── variables.tf             # AWS input variables
│   ├── outputs.tf               # AWS output values
│   ├── terraform.tfvars.example # Example AWS variables file
│   └── versions.tf              # AWS provider versions
├── gcp/                         # Google Cloud Platform configurations
│   ├── main.tf                  # Main GCP infrastructure definition
│   ├── variables.tf             # GCP input variables
│   ├── outputs.tf               # GCP output values
│   ├── terraform.tfvars.example # Example GCP variables file
│   └── versions.tf              # GCP provider versions
├── azure/                       # Microsoft Azure configurations
│   ├── main.tf                  # Main Azure infrastructure definition
│   ├── variables.tf             # Azure input variables
│   ├── outputs.tf               # Azure output values
│   ├── terraform.tfvars.example # Example Azure variables file
│   └── versions.tf              # Azure provider versions
├── modules/                     # Reusable Terraform modules
│   ├── networking/              # VPC, subnets, security groups
│   ├── compute/                 # VM instances, load balancers
│   ├── database/                # Managed database services
│   └── security/                # IAM, security policies
└── scripts/                     # Deployment and automation scripts
    ├── install-docker.sh        # Docker installation script
    ├── deploy-app.sh            # Application deployment script
    ├── cloud-init.yaml          # Cloud-init configuration
    └── health-check.sh          # Health monitoring script
```

## Cloud Platform Support

### AWS (Amazon Web Services)
- **Compute**: EC2 instances with Auto Scaling
- **Networking**: VPC, Internet Gateway, Security Groups
- **Database**: RDS PostgreSQL (optional)
- **Load Balancing**: Application Load Balancer
- **DNS**: Route53 (optional)

### GCP (Google Cloud Platform)
- **Compute**: Compute Engine instances with Instance Groups
- **Networking**: VPC, Firewall rules
- **Database**: Cloud SQL PostgreSQL (optional)
- **Load Balancing**: HTTP(S) Load Balancer
- **DNS**: Cloud DNS (optional)

### Azure (Microsoft Azure)
- **Compute**: Virtual Machines with Scale Sets
- **Networking**: Virtual Network, Network Security Groups
- **Database**: Azure Database for PostgreSQL (optional)
- **Load Balancing**: Azure Load Balancer
- **DNS**: Azure DNS (optional)

## Prerequisites

1. **Terraform Installation**: Version 1.0+ required
2. **Cloud CLI Tools**:
   - AWS: AWS CLI configured with credentials
   - GCP: gcloud CLI authenticated
   - Azure: Azure CLI logged in
3. **Docker Hub Account**: For container registry access
4. **Domain Name**: Optional for custom DNS setup

## Quick Start

1. **Choose your cloud platform**: Navigate to `aws/`, `gcp/`, or `azure/`
2. **Configure variables**: Copy and modify `terraform.tfvars.example`
3. **Initialize Terraform**: `terraform init`
4. **Plan deployment**: `terraform plan`
5. **Deploy infrastructure**: `terraform apply`
6. **Access application**: Use the output URL/IP address

## Security Considerations

- All resources are configured with minimal required permissions
- Security groups/firewall rules allow only necessary ports (80, 443, 22)
- Database access restricted to application subnet
- SSH key-based authentication for VM access
- HTTPS termination at load balancer level

## Cost Optimization

- Default configurations use cost-effective instance sizes
- Auto-scaling configured for demand-based resource allocation
- Spot instances available for development environments
- Resource tagging for cost tracking and management

## Monitoring and Logging

- CloudWatch/Stackdriver/Azure Monitor integration
- Application logs forwarded to cloud logging services
- Health checks configured for load balancers
- Alerting for infrastructure and application metrics

For detailed deployment instructions, see `../deployment/deployment.md`
For AI-assisted development process, see `../deployment/prompts.md`
