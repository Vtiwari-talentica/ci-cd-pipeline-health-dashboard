# AWS Infrastructure Variables
# Configurable parameters for CI/CD Pipeline Health Dashboard deployment

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "ci-cd-dashboard"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "devops-team"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2

  validation {
    condition     = var.availability_zones_count >= 2 && var.availability_zones_count <= 4
    error_message = "Availability zones count must be between 2 and 4."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "min_instances" {
  description = "Minimum number of EC2 instances in ASG"
  type        = number
  default     = 1
}

variable "max_instances" {
  description = "Maximum number of EC2 instances in ASG"
  type        = number
  default     = 3
}

variable "desired_instances" {
  description = "Desired number of EC2 instances in ASG"
  type        = number
  default     = 2
}

variable "public_key" {
  description = "Public key for EC2 key pair"
  type        = string
  default     = ""
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Database Configuration
variable "create_database" {
  description = "Whether to create RDS PostgreSQL database"
  type        = bool
  default     = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "dashboard"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "dashboard_user"
}
