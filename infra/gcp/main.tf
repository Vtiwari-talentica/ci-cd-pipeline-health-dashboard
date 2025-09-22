# GCP Infrastructure for CI/CD Pipeline Health Dashboard
# Generated with AI assistance using ChatGPT and GitHub Copilot

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.84"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
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

# Enable required APIs
resource "google_project_service" "compute" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sql" {
  count              = var.create_database ? 1 : 0
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "monitoring" {
  service            = "monitoring.googleapis.com"
  disable_on_destroy = false
}

# VPC Network
resource "google_compute_network" "main" {
  name                    = "${var.project_name}-${var.environment}-vpc"
  auto_create_subnetworks = false
  
  depends_on = [google_project_service.compute]
}

# Public Subnet
resource "google_compute_subnetwork" "public" {
  name          = "${var.project_name}-${var.environment}-public-subnet"
  ip_cidr_range = var.public_subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id

  secondary_ip_range {
    range_name    = "pod-range"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "service-range"
    ip_cidr_range = "10.2.0.0/16"
  }
}

# Private Subnet for Database
resource "google_compute_subnetwork" "private" {
  count = var.create_database ? 1 : 0

  name          = "${var.project_name}-${var.environment}-private-subnet"
  ip_cidr_range = var.private_subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id
}

# Cloud Router
resource "google_compute_router" "main" {
  name    = "${var.project_name}-${var.environment}-router"
  region  = var.region
  network = google_compute_network.main.id
}

# Cloud NAT
resource "google_compute_router_nat" "main" {
  name   = "${var.project_name}-${var.environment}-nat"
  router = google_compute_router.main.name
  region = var.region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall Rules
resource "google_compute_firewall" "allow_http" {
  name    = "${var.project_name}-${var.environment}-allow-http"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

resource "google_compute_firewall" "allow_app_ports" {
  name    = "${var.project_name}-${var.environment}-allow-app"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["5173", "8001"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ci-cd-dashboard"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.project_name}-${var.environment}-allow-ssh"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_source_ranges
  target_tags   = ["ssh-access"]
}

resource "google_compute_firewall" "allow_health_check" {
  name    = "${var.project_name}-${var.environment}-allow-health-check"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["80", "5173", "8001"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["ci-cd-dashboard"]
}

# Database Firewall (if database is created)
resource "google_compute_firewall" "allow_database" {
  count = var.create_database ? 1 : 0

  name    = "${var.project_name}-${var.environment}-allow-database"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_tags = ["ci-cd-dashboard"]
  target_tags = ["database"]
}

# Service Account
resource "google_service_account" "dashboard" {
  account_id   = "${var.project_name}-${var.environment}-sa"
  display_name = "CI/CD Dashboard Service Account"
  description  = "Service account for CI/CD Dashboard application"
}

# Service Account IAM
resource "google_project_iam_member" "dashboard_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.dashboard.email}"
}

resource "google_project_iam_member" "dashboard_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.dashboard.email}"
}

# Cloud SQL Instance (PostgreSQL)
resource "google_sql_database_instance" "main" {
  count = var.create_database ? 1 : 0

  name             = "${var.project_name}-${var.environment}-db-${random_id.suffix.hex}"
  database_version = "POSTGRES_15"
  region           = var.region

  deletion_protection = var.environment == "prod"

  settings {
    tier = var.db_tier
    
    disk_size    = var.db_disk_size
    disk_type    = "PD_SSD"
    disk_autoresize = true

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
      backup_retention_settings {
        retained_backups = 7
      }
    }

    maintenance_window {
      day  = 7
      hour = 4
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.main.id
      require_ssl     = true
    }

    database_flags {
      name  = "log_statement"
      value = "all"
    }
  }

  depends_on = [
    google_project_service.sql,
    google_service_networking_connection.private_vpc_connection
  ]
}

# Private VPC Connection for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  count = var.create_database ? 1 : 0

  name          = "${var.project_name}-${var.environment}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count = var.create_database ? 1 : 0

  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address[0].name]

  depends_on = [google_project_service.sql]
}

# Database
resource "google_sql_database" "main" {
  count = var.create_database ? 1 : 0

  name     = var.db_name
  instance = google_sql_database_instance.main[0].name
}

# Database User
resource "google_sql_user" "main" {
  count = var.create_database ? 1 : 0

  name     = var.db_username
  instance = google_sql_database_instance.main[0].name
  password = random_password.db_password.result
}

# Instance Template
resource "google_compute_instance_template" "main" {
  name_prefix  = "${var.project_name}-${var.environment}-template-"
  machine_type = var.machine_type
  region       = var.region

  tags = ["ci-cd-dashboard", "http-server", "ssh-access"]

  disk {
    source_image = "ubuntu-os-cloud/ubuntu-2204-lts"
    auto_delete  = true
    boot         = true
    disk_size_gb = var.boot_disk_size
    disk_type    = "pd-standard"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public.id
    
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    ssh-keys = var.ssh_public_key != "" ? "ubuntu:${var.ssh_public_key}" : ""
    user-data = templatefile("${path.module}/../scripts/cloud-init.yaml", {
      db_host     = var.create_database ? google_sql_database_instance.main[0].private_ip_address : "localhost"
      db_name     = var.db_name
      db_username = var.db_username
      db_password = var.create_database ? random_password.db_password.result : "dummy"
      environment = var.environment
    })
  }

  service_account {
    email  = google_service_account.dashboard.email
    scopes = ["cloud-platform"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Health Check
resource "google_compute_health_check" "main" {
  name = "${var.project_name}-${var.environment}-health-check"

  timeout_sec        = 5
  check_interval_sec = 30

  http_health_check {
    port         = "80"
    request_path = "/"
  }
}

# Instance Group Manager
resource "google_compute_region_instance_group_manager" "main" {
  name   = "${var.project_name}-${var.environment}-igm"
  region = var.region

  base_instance_name = "${var.project_name}-${var.environment}"
  target_size        = var.instance_count

  version {
    instance_template = google_compute_instance_template.main.id
  }

  named_port {
    name = "frontend"
    port = 5173
  }

  named_port {
    name = "backend"
    port = 8001
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.main.id
    initial_delay_sec = 300
  }

  update_policy {
    type           = "PROACTIVE"
    minimal_action = "REPLACE"
  }
}

# Load Balancer Backend Services
resource "google_compute_backend_service" "frontend" {
  name        = "${var.project_name}-${var.environment}-frontend-backend"
  protocol    = "HTTP"
  port_name   = "frontend"
  timeout_sec = 30

  backend {
    group = google_compute_region_instance_group_manager.main.instance_group
  }

  health_checks = [google_compute_health_check.main.id]
}

resource "google_compute_backend_service" "backend" {
  name        = "${var.project_name}-${var.environment}-backend-backend"
  protocol    = "HTTP"
  port_name   = "backend"
  timeout_sec = 30

  backend {
    group = google_compute_region_instance_group_manager.main.instance_group
  }

  health_checks = [google_compute_health_check.main.id]
}

# URL Map
resource "google_compute_url_map" "main" {
  name            = "${var.project_name}-${var.environment}-url-map"
  default_service = google_compute_backend_service.frontend.id

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.frontend.id

    path_rule {
      paths   = ["/api/*", "/health", "/docs", "/ws"]
      service = google_compute_backend_service.backend.id
    }
  }
}

# HTTP Proxy
resource "google_compute_target_http_proxy" "main" {
  name    = "${var.project_name}-${var.environment}-http-proxy"
  url_map = google_compute_url_map.main.id
}

# Global Forwarding Rule
resource "google_compute_global_forwarding_rule" "main" {
  name       = "${var.project_name}-${var.environment}-forwarding-rule"
  target     = google_compute_target_http_proxy.main.id
  port_range = "80"
}

# Cloud Monitoring Alert Policy
resource "google_monitoring_alert_policy" "instance_down" {
  display_name = "${var.project_name}-${var.environment} Instance Down"
  combiner     = "OR"

  conditions {
    display_name = "Instance down condition"

    condition_threshold {
      filter          = "resource.type=\"gce_instance\""
      duration        = "300s"
      comparison      = "COMPARISON_LESS_THAN"
      threshold_value = 1

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = []

  depends_on = [google_project_service.monitoring]
}

# Compute Addresses for static IPs (optional)
resource "google_compute_address" "static" {
  count = var.create_static_ip ? 1 : 0

  name   = "${var.project_name}-${var.environment}-static-ip"
  region = var.region
}
