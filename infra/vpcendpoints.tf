resource "aws_vpc_endpoint" "ssm_endpoint" {
  vpc_id             = aws_vpc.Three_Tier_VPC.id
  service_name       = "com.amazonaws.ap-south-1.ssm"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.Private-App-Subnet-AZ-1.id, aws_subnet.Private-App-Subnet-AZ-2.id]
  security_group_ids = [aws_security_group.ssm_endpoint_sg.id]

  private_dns_enabled = true

  tags = {
    Name      = "SSM_VPC_Endpoint"
    createdby = "terraform"
  }
}

resource "aws_vpc_endpoint" "ssm_messages_endpoint" {
  vpc_id             = aws_vpc.Three_Tier_VPC.id
  service_name       = "com.amazonaws.ap-south-1.ssmmessages"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.Private-App-Subnet-AZ-1.id, aws_subnet.Private-App-Subnet-AZ-2.id]
  security_group_ids = [aws_security_group.ssm_endpoint_sg.id]

  private_dns_enabled = true

  tags = {
    Name      = "SSM_Messages_VPC_Endpoint"
    createdby = "terraform"
  }
}

resource "aws_vpc_endpoint" "ec2_messages_endpoint" {
  vpc_id             = aws_vpc.Three_Tier_VPC.id
  service_name       = "com.amazonaws.ap-south-1.ec2messages"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.Private-App-Subnet-AZ-1.id, aws_subnet.Private-App-Subnet-AZ-2.id]
  security_group_ids = [aws_security_group.ssm_endpoint_sg.id]

  private_dns_enabled = true

  tags = {
    Name      = "EC2_Messages_VPC_Endpoint"
    createdby = "terraform"
  }
}