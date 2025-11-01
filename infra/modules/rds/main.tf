
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.vpc_name}-db-subnet-group"
  subnet_ids = var.db_subnets
  tags = {
    Name = "${var.vpc_name}-db-subnet-group"
  }
}

resource "aws_db_instance" "db" {
  allocated_storage = 10
  identifier = "${var.vpc_name}-db"
  db_name           = "${var.vpc_name}_db"
  engine            = var.db_engine
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class

  username = var.db_username
  password = var.db_password

  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.id
  vpc_security_group_ids = [var.db_sg_id]
}
