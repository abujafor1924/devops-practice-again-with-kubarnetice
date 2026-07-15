# ==============================================================================
# TERRAFORM OUTPUTS DEFINITION
# ==============================================================================
# Outputs declare values that are printed to the console after running
# 'terraform apply'. They are also used to share resource endpoints with other
# automation tools or CI/CD pipelines.
# ==============================================================================

output "ec2_public_ip" {
  description = "The public IPv4 address of the host application server (EC2)"
  value       = aws_instance.app_server.public_ip
}

output "ec2_public_dns" {
  description = "The public DNS name of the host application server (EC2)"
  value       = aws_instance.app_server.public_dns
}

output "rds_endpoint" {
  description = "The connection endpoint for the RDS PostgreSQL database instance"
  value       = aws_db_instance.postgres.endpoint
}
