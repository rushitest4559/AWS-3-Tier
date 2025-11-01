
variable "vpc_name" {}

variable "db_subnets" {type = list(string)}

variable "db_sg_id" {}

variable "db_engine" { default = "mysql" }

variable "db_engine_version" { default = "8.0" }

variable "db_instance_class" {
  default = "db.t3.micro"
}

variable "db_username" { default = "admin" }

variable "db_password" { type = string }
