# GCP Infrastructure Outputs
# Essential information about deployed resources

output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}

output "region" {
  description = "GCP region"
  value       = var.region
}

output "zone" {
  description = "GCP zone"
  value       = var.zone
}

output "network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.main.name
}

output "network_self_link" {
  description = "Self link of the VPC network"
  value       = google_compute_network.main.self_link
}

output "public_subnet_name" {
  description = "Name of the public subnet"
  value       = google_compute_subnetwork.public.name
}

output "public_subnet_cidr" {
  description = "CIDR block of the public subnet"
  value       = google_compute_subnetwork.public.ip_cidr_range
}

output "private_subnet_name" {
  description = "Name of the private subnet"
  value       = var.create_database ? google_compute_subnetwork.private[0].name : null
}

output "private_subnet_cidr" {
  description = "CIDR block of the private subnet"
  value       = var.create_database ? google_compute_subnetwork.private[0].ip_cidr_range : null
}

output "load_balancer_ip" {
  description = "External IP address of the load balancer"
  value       = google_compute_global_forwarding_rule.main.ip_address
}

output "application_url" {
  description = "URL to access the CI/CD Dashboard application"
  value       = "http://${google_compute_global_forwarding_rule.main.ip_address}"
}

output "database_connection_name" {
  description = "Cloud SQL connection name"
  value       = var.create_database ? google_sql_database_instance.main[0].connection_name : null
}

output "database_private_ip" {
  description = "Private IP address of the database"
  value       = var.create_database ? google_sql_database_instance.main[0].private_ip_address : null
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

output "service_account_email" {
  description = "Email of the service account"
  value       = google_service_account.dashboard.email
}

output "instance_group_manager_name" {
  description = "Name of the instance group manager"
  value       = google_compute_region_instance_group_manager.main.name
}

output "instance_group_manager_self_link" {
  description = "Self link of the instance group manager"
  value       = google_compute_region_instance_group_manager.main.self_link
}

output "instance_template_name" {
  description = "Name of the instance template"
  value       = google_compute_instance_template.main.name
}

output "instance_template_self_link" {
  description = "Self link of the instance template"
  value       = google_compute_instance_template.main.self_link
}

output "health_check_name" {
  description = "Name of the health check"
  value       = google_compute_health_check.main.name
}

output "backend_service_frontend_name" {
  description = "Name of the frontend backend service"
  value       = google_compute_backend_service.frontend.name
}

output "backend_service_backend_name" {
  description = "Name of the backend backend service"
  value       = google_compute_backend_service.backend.name
}

output "url_map_name" {
  description = "Name of the URL map"
  value       = google_compute_url_map.main.name
}

output "target_proxy_name" {
  description = "Name of the target HTTP proxy"
  value       = google_compute_target_http_proxy.main.name
}

output "forwarding_rule_name" {
  description = "Name of the global forwarding rule"
  value       = google_compute_global_forwarding_rule.main.name
}

output "static_ip_address" {
  description = "Static IP address (if created)"
  value       = var.create_static_ip ? google_compute_address.static[0].address : null
}

output "nat_gateway_name" {
  description = "Name of the Cloud NAT gateway"
  value       = google_compute_router_nat.main.name
}

output "cloud_router_name" {
  description = "Name of the Cloud Router"
  value       = google_compute_router.main.name
}

output "monitoring_alert_policy_name" {
  description = "Name of the monitoring alert policy"
  value       = google_monitoring_alert_policy.instance_down.display_name
}

output "firewall_rules" {
  description = "Names of created firewall rules"
  value = {
    http        = google_compute_firewall.allow_http.name
    app_ports   = google_compute_firewall.allow_app_ports.name
    ssh         = google_compute_firewall.allow_ssh.name
    health_check = google_compute_firewall.allow_health_check.name
    database    = var.create_database ? google_compute_firewall.allow_database[0].name : null
  }
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

# Terraform state information
output "terraform_state_info" {
  description = "Information about Terraform state"
  value = {
    project_name = var.project_name
    project_id   = var.project_id
    environment  = var.environment
    region       = var.region
    zone         = var.zone
    created_at   = timestamp()
  }
}

# Connection information for troubleshooting
output "connection_info" {
  description = "Connection information for troubleshooting"
  value = {
    ssh_command = "gcloud compute ssh --zone=${var.zone} --project=${var.project_id} ubuntu@${var.project_name}-${var.environment}-XXXX"
    console_url = "https://console.cloud.google.com/compute/instances?project=${var.project_id}"
    logs_url    = "https://console.cloud.google.com/logs/query?project=${var.project_id}"
  }
}
