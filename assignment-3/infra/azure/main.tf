# Azure Infrastructure for CI/CD Pipeline Health Dashboard
# Generated with AI assistance using ChatGPT and GitHub Copilot

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.75"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Random password for database
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Random suffix for unique naming
resource "random_id" "suffix" {
  byte_length = 4
}

# Data sources
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
    CreatedBy   = "Terraform"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-${var.environment}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = azurerm_resource_group.main.tags
}

# Public Subnet
resource "azurerm_subnet" "public" {
  name                 = "${var.project_name}-${var.environment}-public-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.public_subnet_cidr]
}

# Private Subnet for Database
resource "azurerm_subnet" "private" {
  count = var.create_database ? 1 : 0

  name                 = "${var.project_name}-${var.environment}-private-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.private_subnet_cidr]

  delegation {
    name = "database-delegation"

    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# Network Security Group for Public Subnet
resource "azurerm_network_security_group" "public" {
  name                = "${var.project_name}-${var.environment}-public-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # HTTP/HTTPS
  security_rule {
    name                       = "HTTP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Application ports
  security_rule {
    name                       = "AppPorts"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["5173", "8001"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # SSH
  security_rule {
    name                       = "SSH"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.ssh_source_cidrs
    destination_address_prefix = "*"
  }

  tags = azurerm_resource_group.main.tags
}

# Network Security Group for Private Subnet
resource "azurerm_network_security_group" "private" {
  count = var.create_database ? 1 : 0

  name                = "${var.project_name}-${var.environment}-private-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # PostgreSQL
  security_rule {
    name                       = "PostgreSQL"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = var.public_subnet_cidr
    destination_address_prefix = "*"
  }

  tags = azurerm_resource_group.main.tags
}

# Associate NSG with Public Subnet
resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.public.id
}

# Associate NSG with Private Subnet
resource "azurerm_subnet_network_security_group_association" "private" {
  count = var.create_database ? 1 : 0

  subnet_id                 = azurerm_subnet.private[0].id
  network_security_group_id = azurerm_network_security_group.private[0].id
}

# Public IP for Load Balancer
resource "azurerm_public_ip" "main" {
  name                = "${var.project_name}-${var.environment}-public-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = azurerm_resource_group.main.tags
}

# Load Balancer
resource "azurerm_lb" "main" {
  name                = "${var.project_name}-${var.environment}-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.main.id
  }

  tags = azurerm_resource_group.main.tags
}

# Backend Address Pool
resource "azurerm_lb_backend_address_pool" "main" {
  loadbalancer_id = azurerm_lb.main.id
  name            = "${var.project_name}-${var.environment}-backend-pool"
}

# Load Balancer Rules
resource "azurerm_lb_rule" "frontend" {
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "Frontend"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 5173
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.frontend.id
}

resource "azurerm_lb_rule" "backend" {
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "Backend"
  protocol                       = "Tcp"
  frontend_port                  = 8001
  backend_port                   = 8001
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.backend.id
}

# Load Balancer Probes
resource "azurerm_lb_probe" "frontend" {
  loadbalancer_id = azurerm_lb.main.id
  name            = "frontend-probe"
  port            = 5173
  protocol        = "Http"
  request_path    = "/"
}

resource "azurerm_lb_probe" "backend" {
  loadbalancer_id = azurerm_lb.main.id
  name            = "backend-probe"
  port            = 8001
  protocol        = "Http"
  request_path    = "/health"
}

# Key Vault (for secrets)
resource "azurerm_key_vault" "main" {
  name                = "${var.project_name}-${var.environment}-kv-${random_id.suffix.hex}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge"
    ]
  }

  tags = azurerm_resource_group.main.tags
}

# Store database password in Key Vault
resource "azurerm_key_vault_secret" "db_password" {
  count = var.create_database ? 1 : 0

  name         = "database-password"
  value        = random_password.db_password.result
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault.main]
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  count = var.create_database ? 1 : 0

  name                   = "${var.project_name}-${var.environment}-psql-${random_id.suffix.hex}"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = "15"
  delegated_subnet_id    = azurerm_subnet.private[0].id
  private_dns_zone_id    = azurerm_private_dns_zone.main[0].id
  administrator_login    = var.db_username
  administrator_password = random_password.db_password.result

  storage_mb = var.db_storage_mb
  sku_name   = var.db_sku_name

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  high_availability {
    mode = "ZoneRedundant"
  }

  maintenance_window {
    day_of_week  = 0
    start_hour   = 4
    start_minute = 0
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.main]

  tags = azurerm_resource_group.main.tags
}

# Private DNS Zone for PostgreSQL
resource "azurerm_private_dns_zone" "main" {
  count = var.create_database ? 1 : 0

  name                = "${var.project_name}-${var.environment}.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name

  tags = azurerm_resource_group.main.tags
}

# Private DNS Zone Virtual Network Link
resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  count = var.create_database ? 1 : 0

  name                  = "${var.project_name}-${var.environment}-dns-link"
  private_dns_zone_name = azurerm_private_dns_zone.main[0].name
  virtual_network_id    = azurerm_virtual_network.main.id
  resource_group_name   = azurerm_resource_group.main.name

  tags = azurerm_resource_group.main.tags
}

# PostgreSQL Database
resource "azurerm_postgresql_flexible_server_database" "main" {
  count = var.create_database ? 1 : 0

  name      = var.db_name
  server_id = azurerm_postgresql_flexible_server.main[0].id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Virtual Machine Scale Set
resource "azurerm_linux_virtual_machine_scale_set" "main" {
  name                = "${var.project_name}-${var.environment}-vmss"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.vm_size
  instances           = var.instance_count
  admin_username      = "azureuser"
  
  disable_password_authentication = true

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Premium_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "primary"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.public.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.main.id]
    }
  }

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  custom_data = base64encode(templatefile("${path.module}/../scripts/cloud-init.yaml", {
    db_host     = var.create_database ? azurerm_postgresql_flexible_server.main[0].fqdn : "localhost"
    db_name     = var.db_name
    db_username = var.db_username
    db_password = var.create_database ? random_password.db_password.result : "dummy"
    environment = var.environment
  }))

  identity {
    type = "SystemAssigned"
  }

  upgrade_mode = "Automatic"

  tags = azurerm_resource_group.main.tags
}

# Auto-scaling settings
resource "azurerm_monitor_autoscale_setting" "main" {
  name                = "${var.project_name}-${var.environment}-autoscale"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.main.id

  profile {
    name = "defaultProfile"

    capacity {
      default = var.instance_count
      minimum = var.min_instances
      maximum = var.max_instances
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }

  tags = azurerm_resource_group.main.tags
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-${var.environment}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 7

  tags = azurerm_resource_group.main.tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "${var.project_name}-${var.environment}-ai"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  tags = azurerm_resource_group.main.tags
}
