
locals {
  private_subnets = {
    for idx, subnet in flatten([
      for az, cidrs in var.private_subnets : [
        for idx, cidr in cidrs : {
          az   = az
          cidr = cidr
          name = "${var.vpc_name}-pvt-${az}-${idx}"
        }
      ]
    ]) : "pvt-sub-${idx}" => subnet
  }
  public_subnets = {
    for idx, subnet in flatten([
      for az, cidrs in var.public_subnets : [
        for idx, cidr in cidrs : {
          az   = az
          cidr = cidr
          name = "${var.vpc_name}-pub-${az}-${idx}"
        }
      ]
    ]) : "pub-sub-${idx}" => subnet
  }
}

resource "aws_subnet" "public" {
  for_each = local.public_subnets
  vpc_id = aws_vpc.main.id

  cidr_block = each.value.cidr
  availability_zone = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name = each.value.name
    Type = "public"
  }
}

resource "aws_subnet" "private" {
  for_each = local.private_subnets
  vpc_id   = aws_vpc.main.id

  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = each.value.name
    Type = "private"
  }
}
