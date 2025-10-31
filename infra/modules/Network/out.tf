
output "private_subnets" {
  value = {
    for az, cidrs in var.private_subnets : 
        az => [for s in values(aws_subnet.private): s.id if s.availability_zone == az]
  }
}

output "public_subnets" {
  value = {
    for az, cidrs in var.public_subnets :
        az => [for s in values(aws_subnet.public): s.id if s.availability_zone == az]
  }
}