# Azure Infrastructure Variables
# Configurable parameters for CI/CD Pipeline Health Dashboard deployment

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "East US"
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

# Network Configuration
variable "vnet_cidr" {
  description = "CIDR block for Virtual Network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "ssh_source_cidrs" {
  description = "Source CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = ""
}

# Compute Configuration
variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_B2s"
}

variable "instance_count" {
  description = "Number of VM instances in the scale set"
  type        = number
  default     = 2

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "min_instances" {
  description = "Minimum number of instances for auto-scaling"
  type        = number
  default     = 1
}

variable "max_instances" {
  description = "Maximum number of instances for auto-scaling"
  type        = number
  default     = 5
}

# Database Configuration
variable "create_database" {
  description = "Whether to create PostgreSQL Flexible Server"
  type        = bool
  default     = true
}

variable "db_sku_name" {
  description = "PostgreSQL Flexible Server SKU"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "db_storage_mb" {
  description = "PostgreSQL storage in MB"
  type        = number
  default     = 32768
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

# Monitoring Configuration
variable "enable_monitoring" {
  description = "Enable Azure Monitor and Application Insights"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log retention period in days"
  type        = number
  default     = 7

  validation {
    condition     = var.log_retention_days >= 7 && var.log_retention_days <= 730
    error_message = "Log retention days must be between 7 and 730."
  }
}
