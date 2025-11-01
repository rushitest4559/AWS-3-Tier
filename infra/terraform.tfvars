vpc_name = "rushivpc"
vpc_cidr = "10.0.0.0/16"

public_subnets = {
  "ap-south-1a" = ["10.0.0.0/24"]
  "ap-south-1b" = ["10.0.1.0/24"]
}
private_subnets = {
  "ap-south-1a" = ["10.0.2.0/24", "10.0.3.0/24"]
  "ap-south-1b" = ["10.0.4.0/24", "10.0.5.0/24"]
}

security_groups = {
  "INTERNET FACING LB SG" = {
    igress = [{ port = 80, reference_sg = null, cidr = "0.0.0.0/0" }]
    egress = []
  }
  "WEB SG" = {
    igress = [{ port = 80, reference_sg = "INTERNET FACING LB SG", cidr = null }]
    egress = []
  }
  "INTERNAL LB SG" = {
    igress = [{ port = 80, reference_sg = "WEB SG", cidr = null }]
    egress = []
  }
  "APP SG" = {
    igress = [{ port = 4000, reference_sg = "INTERNAL LB SG", cidr = null }]
    egress = []
  }
  "RDS SG" = {
    igress = [{ port = 3306, reference_sg = "APP SG", cidr = null }]
    egress = []
  }
}

