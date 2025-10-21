resource "aws_lb" "front_end" {
  name               = "front-end-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Internet_Facing_LB_SG.id]
  subnets            = [aws_subnet.Public-Web-Subnet-AZ-1.id, aws_subnet.Public-Web-Subnet-AZ-2.id]
}

resource "aws_lb_target_group" "front_end" {
  name     = "front-end-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.Three_Tier_VPC.id
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.front_end.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_end.arn
  }
}

resource "aws_lb" "back_end" {
  name               = "back-end-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Internal_LB_SG.id]
  subnets            = [aws_subnet.Private-App-Subnet-AZ-1.id, aws_subnet.Private-App-Subnet-AZ-2.id]
}

resource "aws_lb_target_group" "back_end" {
  name     = "back-end-tg"
  port     = 4000
  protocol = "HTTP"
  vpc_id   = aws_vpc.Three_Tier_VPC.id
}

resource "aws_lb_listener" "back_end" {
  load_balancer_arn = aws_lb.back_end.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.back_end.arn
  }
}
