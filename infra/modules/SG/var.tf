
variable "vpc_id" {
  
}

variable "vpc_name" {
  
}

variable "security_groups" {
  type = map(map(list(map(string))))
}

