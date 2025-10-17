resource "aws_security_group" "Internet_Facing_LB_SG" {
  name   = "Internet_Facing_LB_SG"
  vpc_id = aws_vpc.Three_Tier_VPC.id

  tags = {
    Name      = "Internet_Facing_LB_SG"
    createdby = "terraform"
  }
}

resource "aws_security_group" "Web_Instance_SG" {
  name   = "Web_Instance_SG"
  vpc_id = aws_vpc.Three_Tier_VPC.id

  tags = {
    Name      = "Web_Instance_SG"
    createdby = "terraform"
  }
}

resource "aws_security_group" "Internal_LB_SG" {
  name   = "Internal_LB_SG"
  vpc_id = aws_vpc.Three_Tier_VPC.id

  tags = {
    Name      = "Internal_LB_SG"
    createdby = "terraform"
  }
}

resource "aws_security_group" "App_Instance_SG" {
  name   = "App_Instance_SG"
  vpc_id = aws_vpc.Three_Tier_VPC.id

  tags = {
    Name      = "App_Instance_SG"
    createdby = "terraform"
  }
}

resource "aws_security_group" "DB_SG" {
  name   = "DB_SG"
  vpc_id = aws_vpc.Three_Tier_VPC.id

  tags = {
    Name      = "DB_SG"
    createdby = "terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_from_world" {
  security_group_id = aws_security_group.Internet_Facing_LB_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "send_http_to_web_instance" {
  security_group_id            = aws_security_group.Internet_Facing_LB_SG.id
  referenced_security_group_id = aws_security_group.Web_Instance_SG.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_from_public_lb" {
  security_group_id            = aws_security_group.Web_Instance_SG.id
  referenced_security_group_id = aws_security_group.Internet_Facing_LB_SG.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
}

resource "aws_vpc_security_group_egress_rule" "send_http_to_internal_lb" {
  security_group_id            = aws_security_group.Web_Instance_SG.id
  referenced_security_group_id = aws_security_group.Internal_LB_SG.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_from_web_instance" {
  security_group_id            = aws_security_group.Internal_LB_SG.id
  referenced_security_group_id = aws_security_group.Web_Instance_SG.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
}

resource "aws_vpc_security_group_egress_rule" "send_4000_to_app_instance" {
  security_group_id            = aws_security_group.Internal_LB_SG.id
  referenced_security_group_id = aws_security_group.App_Instance_SG.id
  from_port                    = 4000
  ip_protocol                  = "tcp"
  to_port                      = 4000
}

resource "aws_vpc_security_group_ingress_rule" "allow_4000_from_internal_lb" {
  security_group_id            = aws_security_group.App_Instance_SG.id
  referenced_security_group_id = aws_security_group.Internal_LB_SG.id
  from_port                    = 4000
  ip_protocol                  = "tcp"
  to_port                      = 4000
}

resource "aws_vpc_security_group_egress_rule" "send_3306_to_db" {
  security_group_id            = aws_security_group.App_Instance_SG.id
  referenced_security_group_id = aws_security_group.DB_SG.id
  from_port                    = 3306
  ip_protocol                  = "tcp"
  to_port                      = 3306
}

resource "aws_vpc_security_group_ingress_rule" "allow_3306_from_app_instance" {
  security_group_id            = aws_security_group.DB_SG.id
  referenced_security_group_id = aws_security_group.App_Instance_SG.id
  from_port                    = 3306
  ip_protocol                  = "tcp"
  to_port                      = 3306
}