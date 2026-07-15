# ==============================================================================
# TERRAFORM VARIABLES DEFINITION
# ==============================================================================
# Variables allow you to parameterize your configurations, making them reusable
# across different environments (e.g. dev, staging, prod) without changing code.
# ==============================================================================

variable "aws_region" {
  type        = string
  description = "The target AWS region where resources will be provisioned"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "The environment label for resource naming and tags"
  default     = "dev"
}

variable "instance_type" {
  type        = string
  description = "The hardware size of the EC2 instance virtual machine"
  default     = "t3.micro" # 2 vCPU, 1GiB RAM. Free tier eligible.
}

variable "db_name" {
  type        = string
  description = "The name of the database to be created inside the RDS instance"
  default     = "mydatabase"
}

variable "db_username" {
  type        = string
  description = "Master administrative username for the PostgreSQL database"
  default     = "myuser"
}

variable "db_password" {
  type        = string
  description = "Master database password. Marked sensitive to prevent leaking in console prints."
  default     = "mypassword"
  sensitive   = true # Hides the value in CLI output logs
}
