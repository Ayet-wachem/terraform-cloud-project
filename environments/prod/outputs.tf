output "alb_dns_name" {
  description = "Nom DNS public de l'Application Load Balancer."
  value       = module.load_balancer.alb_dns_name
}
output "application_url" {
  description = "URL HTTP ou HTTPS de l'application."
  value       = var.certificate_arn == null ? "http://${module.load_balancer.alb_dns_name}" : "https://${module.load_balancer.alb_dns_name}"
}
output "rds_endpoint" {
  description = "Endpoint privé RDS (pas une URL publique)."
  value       = module.database.rds_endpoint
}
output "rds_secret_arn" {
  description = "ARN du secret maître géré par RDS."
  value       = module.database.master_secret_arn
}
output "s3_bucket_name" { value = module.storage.bucket_name }
output "autoscaling_group_name" { value = module.compute.autoscaling_group_name }
output "vpc_id" { value = module.network.vpc_id }
