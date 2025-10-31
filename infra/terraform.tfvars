vpc_name = "rushi-vpc"
vpc_cidr = "10.0.0.0/16"

public_subnets = {
  "ap-south-1a" = [ "10.0.0.0/24" ]
  "ap-south-1b" = [ "10.0.1.0/24" ]
}
private_subnets = {
  "ap-south-1a" = [ "10.0.2.0/24", "10.0.3.0/24" ]
  "ap-south-1b" = [ "10.0.4.0/24", "10.0.5.0/24" ]
}