resource "aws_db_subnet_group" "three_tier_pro_db_subnet_group" {
  name = "three_tier_pro_db_subnet_group"
  subnet_ids = [
    aws_subnet.Private-DB-Subnet-AZ-1.id,
    aws_subnet.Private-DB-Subnet-AZ-2.id
  ]

  tags = {
    Name       = "Three_Tier_Pro_DB_Subnet_group"
    created_by = "Terraform"
  }
}

resource "aws_db_instance" "Three_Tier_DB" {
  identifier             = "three-tier-db"
  db_name                = "Three_Tier_DB"
  username               = "admin"
  password               = "YourPassword123!"
  allocated_storage      = 10
  instance_class         = "db.t3.micro"
  engine                 = "mysql"
  db_subnet_group_name   = aws_db_subnet_group.three_tier_pro_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.DB_SG.id]
  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = {
    Name       = "Three_Tier_DB"
    created_by = "Terraform"
  }
}