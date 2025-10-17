resource "aws_autoscaling_group" "front_end" {
  name = "front-end-asg"
  launch_template {
    id      = aws_launch_template.front_end.id
    version = "$Latest"
  }
  vpc_zone_identifier = [
    aws_subnet.Public-Web-Subnet-AZ-1.id,
    aws_subnet.Public-Web-Subnet-AZ-2.id
  ]
  target_group_arns = [aws_lb_target_group.front_end.arn]
  desired_capacity  = 1
  min_size          = 1
  max_size          = 2
}

resource "aws_autoscaling_group" "back_end" {
  name = "back-end-asg"
  launch_template {
    id      = aws_launch_template.back_end.id
    version = "$Latest"
  }
  vpc_zone_identifier = [
    aws_subnet.Private-App-Subnet-AZ-1.id,
    aws_subnet.Private-App-Subnet-AZ-2.id
  ]
  target_group_arns = [aws_lb_target_group.back_end.arn]
  desired_capacity  = 1
  min_size          = 1
  max_size          = 2
}