terraform {
  backend "s3" {}

  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = local.common_tags
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "Terraform"
  }
}

module "network" {
  source               = "../../modules/network"
  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  app_subnet_cidrs     = var.app_subnet_cidrs
  db_subnet_cidrs      = var.db_subnet_cidrs
  availability_zones  = var.availability_zones
  single_nat_gateway   = var.single_nat_gateway
  tags                 = local.common_tags
}

module "security" {
  source      = "../../modules/security"
  name_prefix = local.name_prefix
  vpc_id      = module.network.vpc_id
  enable_https = var.certificate_arn != null
  tags        = local.common_tags
}

module "load_balancer" {
  source            = "../../modules/load-balancer"
  name_prefix       = local.name_prefix
  public_subnet_ids = module.network.public_subnet_ids
  security_group_id = module.security.alb_security_group_id
  vpc_id            = module.network.vpc_id
  certificate_arn   = var.certificate_arn
  tags              = local.common_tags
}

module "compute" {
  source                = "../../modules/compute"
  name_prefix           = local.name_prefix
  app_subnet_ids        = module.network.app_subnet_ids
  security_group_id     = module.security.app_security_group_id
  instance_profile_name = module.security.instance_profile_name
  target_group_arn      = module.load_balancer.target_group_arn
  instance_type         = var.instance_type
  min_size              = var.min_size
  max_size              = var.max_size
  desired_capacity      = var.desired_capacity
  tags                  = local.common_tags
}

module "database" {
  source              = "../../modules/database"
  name_prefix         = local.name_prefix
  db_subnet_ids       = module.network.db_subnet_ids
  security_group_id   = module.security.db_security_group_id
  db_instance_class   = var.db_instance_class
  multi_az            = var.db_multi_az
  deletion_protection = var.db_deletion_protection
  skip_final_snapshot = var.db_skip_final_snapshot
  db_name             = var.db_name
  db_username         = var.db_username
  tags                = local.common_tags
}

module "storage" {
  source      = "../../modules/storage"
  name_prefix = local.name_prefix
  tags        = local.common_tags
}
