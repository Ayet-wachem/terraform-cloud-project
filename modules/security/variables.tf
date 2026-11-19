variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "tags" { type = map(string) }

variable "enable_https" {
  description = "Autoriser HTTPS sur le Load Balancer uniquement si un certificat ACM est configuré."
  type        = bool
  default     = false
}
