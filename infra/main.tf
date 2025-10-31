
module "Network" {
  source = "./modules/Network"
  vpc_name = var.vpc_name
  vpc_cidr = var.vpc_cidr
  public_subnets = var.public_subnets
  private_subnets = var.private_subnets
}