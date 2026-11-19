variable "name_prefix" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "security_group_id" { type = string }
variable "vpc_id" { type = string }
variable "certificate_arn" {
  description = "ARN ACM optionnel; doit être dans la même région que l'ALB."
  type        = string
  default     = null
}
variable "tags" { type = map(string) }
