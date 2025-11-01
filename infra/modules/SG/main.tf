

resource "aws_security_group" "security_groups" {
  for_each = var.security_groups

  name = each.key
  vpc_id = var.vpc_id
  tags = {
    Name = each.key
  }
}

locals {
  sg_name_to_id = {
    for name, sg in aws_security_group.security_groups :
    name => sg.id
  }

  ingress_rules = flatten([
    for sg_name, sg_data in var.security_groups : [
      for rule in sg_data.igress : {
        sg_name      = sg_name
        port         = rule.port
        cidr         = rule.cidr
        reference_id = rule.reference_sg != null ? local.sg_name_to_id[rule.reference_sg] : null
      }
    ]
  ])
}


resource "aws_vpc_security_group_ingress_rule" "security_groups_ingress" {
  for_each = {
    for idx, rule in local.ingress_rules : 
        "${rule.sg_name}-${idx}" => rule
  }

  security_group_id = local.sg_name_to_id[each.value.sg_name]
  from_port = each.value.port
  to_port = each.value.port
  ip_protocol = "tcp"
  cidr_ipv4 = each.value.cidr
  referenced_security_group_id = each.value.reference_id
}

resource "aws_vpc_security_group_egress_rule" "security_groups_egress" {
  for_each = {for k, v in aws_security_group.security_groups : k => v}
  security_group_id = each.value.id
  ip_protocol = "-1"
  cidr_ipv4 = "0.0.0.0/0"
}