resource "aws_vpc" "Three_Tier_VPC" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name      = "Three_Tier_VPC"
    createdby = "terraform"
  }
}

resource "aws_subnet" "Public-Web-Subnet-AZ-1" {
  vpc_id            = aws_vpc.Three_Tier_VPC.id
  availability_zone = "ap-south-1a"
  cidr_block        = "10.0.1.0/24"

  map_public_ip_on_launch = true

  tags = {
    Name      = "Public-Web-Subnet-AZ-1"
    createdby = "terraform"
  }
}

resource "aws_subnet" "Private-App-Subnet-AZ-1" {
  vpc_id            = aws_vpc.Three_Tier_VPC.id
  availability_zone = "ap-south-1a"
  cidr_block        = "10.0.2.0/24"

  tags = {
    Name      = "Private-App-Subnet-AZ-1"
    createdby = "terraform"
  }
}

resource "aws_subnet" "Private-DB-Subnet-AZ-1" {
  vpc_id            = aws_vpc.Three_Tier_VPC.id
  availability_zone = "ap-south-1a"
  cidr_block        = "10.0.3.0/24"

  tags = {
    Name      = "Private-DB-Subnet-AZ-1"
    createdby = "terraform"
  }
}

resource "aws_subnet" "Public-Web-Subnet-AZ-2" {
  vpc_id            = aws_vpc.Three_Tier_VPC.id
  availability_zone = "ap-south-1b"
  cidr_block        = "10.0.4.0/24"

  map_public_ip_on_launch = true

  tags = {
    Name      = "Public-Web-Subnet-AZ-2"
    createdby = "terraform"
  }
}

resource "aws_subnet" "Private-App-Subnet-AZ-2" {
  vpc_id            = aws_vpc.Three_Tier_VPC.id
  availability_zone = "ap-south-1b"
  cidr_block        = "10.0.5.0/24"

  tags = {
    Name      = "Private-App-Subnet-AZ-2"
    createdby = "terraform"
  }
}

resource "aws_subnet" "Private-DB-Subnet-AZ-2" {
  vpc_id            = aws_vpc.Three_Tier_VPC.id
  availability_zone = "ap-south-1b"
  cidr_block        = "10.0.6.0/24"

  tags = {
    Name      = "Private-DB-Subnet-AZ-2"
    createdby = "terraform"
  }
}

resource "aws_internet_gateway" "Three_Tier_VPC_IGW" {
  vpc_id = aws_vpc.Three_Tier_VPC.id

  tags = {
    Name      = "Three_Tier_VPC_IGW"
    createdby = "terraform"
  }
}

resource "aws_route_table" "Three_Tier_VPC_Public_RT" {
  vpc_id = aws_vpc.Three_Tier_VPC.id
  tags = {
    Name      = "Three_Tier_VPC_Public_RT"
    createdby = "terraform"
  }
}

resource "aws_route" "Three_Tier_VPC_IGW_Route" {
  route_table_id         = aws_route_table.Three_Tier_VPC_Public_RT.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.Three_Tier_VPC_IGW.id
}

resource "aws_route_table_association" "Public-Web-Subnet-AZ-1-Association" {
  subnet_id      = aws_subnet.Public-Web-Subnet-AZ-1.id
  route_table_id = aws_route_table.Three_Tier_VPC_Public_RT.id
}
resource "aws_route_table_association" "Public-Web-Subnet-AZ-2-Association" {
  subnet_id      = aws_subnet.Public-Web-Subnet-AZ-2.id
  route_table_id = aws_route_table.Three_Tier_VPC_Public_RT.id
}