
module "Network" {
  source = "./modules/Network"
  vpc_name = var.vpc_name
  vpc_cidr = var.vpc_cidr
  public_subnets = var.public_subnets
  private_subnets = var.private_subnets
}

module "SG" {
  source = "./modules/SG"
  vpc_id = module.Network.vpc_id
  vpc_name = var.vpc_name
  security_groups = var.security_groups
}

locals {
  db_subnets = flatten([
    for az, subnets in module.Network.private_subnets : [
      for idx, subnet in subnets : subnet if idx == 1
    ]
  ])
}

module "RDS" {
  source = "./modules/rds"
  vpc_name = var.vpc_name
  db_subnets = local.db_subnets
  db_password = "admin123"
  db_sg_id = module.SG.security_groups_ids["RDS SG"]
}