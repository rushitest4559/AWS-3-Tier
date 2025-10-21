output "vpc_id" {
  description = "ID of a vpc created by this terraform configuration"
  value       = aws_vpc.Three_Tier_VPC.id
}

output "public_subnet_id" {
  description = "Subnet IDs of 2 public subnets present in vpc"
  value       = aws_subnet.Public-Web-Subnet-AZ-1.id
}

output "builder_instance_sg_id" {
  description = "Security Group ID of the builder instance"
  value       = aws_security_group.builder_instance_sg.id

}

output "front_end_LT_id" {
  description = "ID of the front-end launch template"
  value       = aws_launch_template.front_end.id
}

output "back_end_LT_id" {
  description = "ID of the back-end launch template"
  value       = aws_launch_template.back_end.id
}

output "front_end_autoscaling_group_name" {
  description = "Name of frontend autoscaling group"
  value       = aws_autoscaling_group.front_end.name
}

output "back_end_autoscaling_group_name" {
  description = "Name of backend autoscaling group"
  value       = aws_autoscaling_group.back_end.name
}

output "rds_endpoint" {
  description = "endpoint of an rds database"
  value = aws_db_instance.Three_Tier_DB.endpoint
}

output "rds_username" {
  description = "username of an rds"
  value = aws_db_instance.Three_Tier_DB.username
}

output "rds_password" {
  description = "password of an rds"
  value = aws_db_instance.Three_Tier_DB.password
  sensitive = true
}

output "backend_lb_address" {
  description = "backend load balancer dns"
  value = aws_lb.back_end.dns_name
}