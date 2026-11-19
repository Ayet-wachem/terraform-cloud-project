resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(var.tags, { Name = "${var.name_prefix}-vpc" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name_prefix}-igw" })
}

locals {
  public_subnets = {
    for index, cidr in var.public_subnet_cidrs : tostring(index) => {
      cidr = cidr
      az   = var.availability_zones[index]
    }
  }
  app_subnets = {
    for index, cidr in var.app_subnet_cidrs : tostring(index) => {
      cidr = cidr
      az   = var.availability_zones[index]
    }
  }
  db_subnets = {
    for index, cidr in var.db_subnet_cidrs : tostring(index) => {
      cidr = cidr
      az   = var.availability_zones[index]
    }
  }
  nat_keys = var.single_nat_gateway ? ["0"] : keys(local.public_subnets)
}

resource "aws_subnet" "public" {
  for_each                = local.public_subnets
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
  tags = merge(var.tags, { Name = "${var.name_prefix}-public-${each.key}" })
}

resource "aws_subnet" "app" {
  for_each          = local.app_subnets
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags = merge(var.tags, { Name = "${var.name_prefix}-app-${each.key}" })
}

resource "aws_subnet" "db" {
  for_each          = local.db_subnets
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags = merge(var.tags, { Name = "${var.name_prefix}-db-${each.key}" })
}

resource "aws_eip" "nat" {
  for_each = toset(local.nat_keys)
  domain   = "vpc"
  tags     = merge(var.tags, { Name = "${var.name_prefix}-nat-eip-${each.key}" })
}

resource "aws_nat_gateway" "this" {
  for_each      = toset(local.nat_keys)
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id
  depends_on    = [aws_internet_gateway.this]
  tags          = merge(var.tags, { Name = "${var.name_prefix}-nat-${each.key}" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = merge(var.tags, { Name = "${var.name_prefix}-public-rt" })
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "app" {
  for_each = toset(local.nat_keys)
  vpc_id   = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[each.key].id
  }
  tags = merge(var.tags, { Name = "${var.name_prefix}-app-rt-${each.key}" })
}

resource "aws_route_table_association" "app" {
  for_each = aws_subnet.app
  subnet_id = each.value.id
  route_table_id = aws_route_table.app[
    var.single_nat_gateway ? "0" : each.key
  ].id
}

resource "aws_route_table" "db" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name_prefix}-db-rt" })
}

resource "aws_route_table_association" "db" {
  for_each       = aws_subnet.db
  subnet_id      = each.value.id
  route_table_id = aws_route_table.db.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [for rt in aws_route_table.app : rt.id]
  tags              = merge(var.tags, { Name = "${var.name_prefix}-s3-endpoint" })
}

data "aws_region" "current" {}
