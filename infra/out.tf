
output "security_groups_ids" {
  value = module.SG.security_groups_ids
}
output "private_subnets" {
  value = module.Network.private_subnets
}

output "public_subnets" {
  value = module.Network.public_subnets
}

output "vpc_id" {
  value = module.Network.vpc_id
}