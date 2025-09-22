# AWS Infrastructure Outputs
# Essential information about deployed resources

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "load_balancer_dns" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "load_balancer_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "application_url" {
  description = "URL to access the CI/CD Dashboard application"
  value       = "http://${aws_lb.main.dns_name}"
}

output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = var.create_database ? aws_db_instance.main[0].endpoint : null
}

output "database_port" {
  description = "RDS instance port"
  value       = var.create_database ? aws_db_instance.main[0].port : null
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

output "auto_scaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

output "auto_scaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.arn
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.main.id
}

output "security_group_alb_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "security_group_ec2_id" {
  description = "ID of the EC2 security group"
  value       = aws_security_group.ec2.id
}

output "security_group_rds_id" {
  description = "ID of the RDS security group"
  value       = var.create_database ? aws_security_group.rds[0].id : null
}

output "key_pair_name" {
  description = "Name of the EC2 key pair"
  value       = aws_key_pair.dashboard_key.key_name
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.dashboard.name
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "availability_zones" {
  description = "Availability zones used"
  value       = data.aws_availability_zones.available.names
}

# Terraform state information
output "terraform_state_info" {
  description = "Information about Terraform state"
  value = {
    project_name = var.project_name
    environment  = var.environment
    region       = var.aws_region
    created_at   = timestamp()
  }
}
