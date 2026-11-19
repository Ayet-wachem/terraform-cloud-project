variable "aws_region" {
  description = "Région AWS du bucket de state."
  type        = string
  default     = "eu-west-1"
}

variable "state_bucket_name" {
  description = "Nom S3 globalement unique pour le backend Terraform."
  type        = string
}
