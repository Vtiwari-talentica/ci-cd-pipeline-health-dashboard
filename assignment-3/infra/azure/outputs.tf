# Azure Infrastructure Outputs
# Essential information about deployed resources

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

output "virtual_network_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "virtual_network_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "public_subnet_name" {
  description = "Name of the public subnet"
  value       = azurerm_subnet.public.name
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = azurerm_subnet.public.id
}

output "private_subnet_name" {
  description = "Name of the private subnet"
  value       = var.create_database ? azurerm_subnet.private[0].name : null
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = var.create_database ? azurerm_subnet.private[0].id : null
}

output "public_ip_address" {
  description = "Public IP address of the load balancer"
  value       = azurerm_public_ip.main.ip_address
}

output "load_balancer_name" {
  description = "Name of the load balancer"
  value       = azurerm_lb.main.name
}

output "load_balancer_id" {
  description = "ID of the load balancer"
  value       = azurerm_lb.main.id
}

output "application_url" {
  description = "URL to access the CI/CD Dashboard application"
  value       = "http://${azurerm_public_ip.main.ip_address}"
}

output "database_fqdn" {
  description = "Fully qualified domain name of the database server"
  value       = var.create_database ? azurerm_postgresql_flexible_server.main[0].fqdn : null
}

output "database_name" {
  description = "Database name"
  value       = var.db_name
}

output "database_username" {
  description = "Database username"
  value       = var.db_username
  sensitive   = true
}

output "database_password" {
  description = "Database password"
  value       = random_password.db_password.result
  sensitive   = true
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "vm_scale_set_name" {
  description = "Name of the VM scale set"
  value       = azurerm_linux_virtual_machine_scale_set.main.name
}

output "vm_scale_set_id" {
  description = "ID of the VM scale set"
  value       = azurerm_linux_virtual_machine_scale_set.main.id
}

output "autoscale_setting_name" {
  description = "Name of the autoscale setting"
  value       = azurerm_monitor_autoscale_setting.main.name
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "application_insights_name" {
  description = "Name of Application Insights"
  value       = azurerm_application_insights.main.name
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "network_security_group_public_name" {
  description = "Name of the public network security group"
  value       = azurerm_network_security_group.public.name
}

output "network_security_group_private_name" {
  description = "Name of the private network security group"
  value       = var.create_database ? azurerm_network_security_group.private[0].name : null
}

output "private_dns_zone_name" {
  description = "Name of the private DNS zone"
  value       = var.create_database ? azurerm_private_dns_zone.main[0].name : null
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "location" {
  description = "Azure region"
  value       = var.location
}

# Terraform state information
output "terraform_state_info" {
  description = "Information about Terraform state"
  value = {
    project_name        = var.project_name
    environment         = var.environment
    location            = var.location
    resource_group_name = azurerm_resource_group.main.name
    created_at          = timestamp()
  }
}

# Connection information for troubleshooting
output "connection_info" {
  description = "Connection information for troubleshooting"
  value = {
    ssh_command   = "az vmss list-instance-connection-info --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_linux_virtual_machine_scale_set.main.name}"
    portal_url    = "https://portal.azure.com/#@/resource${azurerm_resource_group.main.id}"
    logs_url      = "https://portal.azure.com/#@/resource${azurerm_log_analytics_workspace.main.id}"
    insights_url  = "https://portal.azure.com/#@/resource${azurerm_application_insights.main.id}"
  }
}

# Resource IDs for advanced configurations
output "resource_ids" {
  description = "Important resource IDs for advanced configurations"
  value = {
    resource_group_id     = azurerm_resource_group.main.id
    virtual_network_id    = azurerm_virtual_network.main.id
    public_subnet_id      = azurerm_subnet.public.id
    private_subnet_id     = var.create_database ? azurerm_subnet.private[0].id : null
    load_balancer_id      = azurerm_lb.main.id
    vm_scale_set_id       = azurerm_linux_virtual_machine_scale_set.main.id
    key_vault_id          = azurerm_key_vault.main.id
    database_server_id    = var.create_database ? azurerm_postgresql_flexible_server.main[0].id : null
    log_analytics_id      = azurerm_log_analytics_workspace.main.id
    application_insights_id = azurerm_application_insights.main.id
  }
}
