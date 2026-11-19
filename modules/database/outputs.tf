output "rds_endpoint" { value = aws_db_instance.this.address }
output "rds_port" { value = aws_db_instance.this.port }
output "rds_identifier" { value = aws_db_instance.this.identifier }
output "master_secret_arn" {
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
  description = "Secret géré par RDS/Secrets Manager; ne pas afficher sa valeur dans les logs."
}
