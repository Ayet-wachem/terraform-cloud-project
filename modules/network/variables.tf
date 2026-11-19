variable "name_prefix" { type = string }
variable "vpc_cidr" { type = string }
variable "public_subnet_cidrs" { type = list(string) }
variable "app_subnet_cidrs" { type = list(string) }
variable "db_subnet_cidrs" { type = list(string) }
variable "availability_zones" { type = list(string) }
variable "single_nat_gateway" {
  description = "Un seul NAT pour dev/test; false = un NAT par AZ pour une meilleure résilience."
  type        = bool
}
variable "tags" { type = map(string) }
