resource "aws_iam_role" "iam_ec2_ssm_role" {
  name = "iam_ec2_ssm_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name      = "iam_ec2_ssm_role"
    createdby = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "ec2ssmpolicyattach" {
  role       = aws_iam_role.iam_ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 2. IAM Instance Profile (The resource that links the Role to the EC2 instance)
resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "ec2-ssm-instance-profile" # Choose a profile name
  role = aws_iam_role.iam_ec2_ssm_role.name
}