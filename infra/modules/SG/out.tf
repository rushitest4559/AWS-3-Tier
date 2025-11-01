
output "security_groups_ids" {
  value = {
    for idx, sg in aws_security_group.security_groups :
        sg.name => sg.id
  }
}