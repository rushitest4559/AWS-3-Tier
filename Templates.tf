resource "aws_launch_template" "front_end" {
  name          = "front-end-launch-template"
  image_id      = "ami-06fa3f12191aa3337"
  instance_type = "t2.micro"
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ssm_profile.name
  }
  vpc_security_group_ids = [aws_security_group.Web_Instance_SG.id]
}

resource "aws_launch_template" "back_end" {
  name          = "back-end-launch-template"
  image_id      = "ami-06fa3f12191aa3337"
  instance_type = "t2.micro"
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ssm_profile.name
  }
  vpc_security_group_ids = [aws_security_group.App_Instance_SG.id]
}