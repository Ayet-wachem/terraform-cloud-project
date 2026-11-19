variable "aws_region" {
  description = "Région AWS."
  type        = string
  default     = "eu-west-1"
}
variable "project_name" {
  description = "Préfixe du projet."
  type        = string
  default     = "cloud5"
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name doit contenir uniquement minuscules, chiffres et tirets."
  }
}
variable "environment" {
  description = "Environnement isolé."
  type        = string
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment doit être dev, test ou prod."
  }
}
variable "owner" {
  description = "Responsable du projet (tag)."
  type        = string
}
variable "vpc_cidr" {
  description = "CIDR du VPC."
  type        = string
  default     = "10.20.0.0/16"
}
variable "availability_zones" {
  description = "Deux AZ disponibles dans la région."
  type        = list(string)
  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "Fournir exactement deux Availability Zones."
  }
}
variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.1.0/24", "10.20.2.0/24"]
  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Deux subnets publics sont requis."
  }
}
variable "app_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.11.0/24", "10.20.12.0/24"]
  validation {
    condition     = length(var.app_subnet_cidrs) == 2
    error_message = "Deux subnets applicatifs sont requis."
  }
}
variable "db_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.21.0/24", "10.20.22.0/24"]
  validation {
    condition     = length(var.db_subnet_cidrs) == 2
    error_message = "Deux subnets DB sont requis."
  }
}
variable "single_nat_gateway" {
  description = "True réduit les coûts mais crée un point unique de sortie."
  type        = bool
}
variable "instance_type" {
  type    = string
  default = "t3.micro"
}
variable "min_size" {
  type    = number
  default = 2
  validation {
    condition     = var.min_size >= 2
    error_message = "Le projet exige au moins deux instances."
  }
}
variable "max_size" {
  type    = number
  default = 4
}
variable "desired_capacity" {
  type    = number
  default = 2
}
variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}
variable "db_multi_az" { type = bool }
variable "db_deletion_protection" { type = bool }
variable "db_skip_final_snapshot" { type = bool }
variable "db_name" {
  type    = string
  default = "cloudapp"
}
variable "db_username" {
  type    = string
  default = "cloudadmin"
}
variable "certificate_arn" {
  description = "ARN ACM optionnel pour activer HTTPS."
  type        = string
  default     = null
}
