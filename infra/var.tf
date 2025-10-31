

variable "vpc_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnets" {
  type = map(list(string))
}

variable "private_subnets" {
  type = map(list(string))
}