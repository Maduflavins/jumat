output "subnet_1_id" {
  value = aws_subnet.subnet_1.id
}


output "subnet_2_id" {
  value = aws_subnet.subnet_2.id
}

output "security_group_id_app" {
  value = aws_security_group.app_nodes.id
}

output "security_group_id_db" {
  value = aws_security_group.db_nodes.id
}

# output "security_group_rules_id_db" {
#   value = aws_security_group_rule.db_connection.id
  
# }

output "vpc_id" {
  value = aws_vpc.vpc.id
  
}

output "jumia_validator_lb_sg_id" {
  value = aws_security_group.jumia_validator_lb.id
  
}

output "jumia_validator_tg_arn" {
  value = aws_alb_target_group.jumia_validator_tg.arn
  
}
