output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "c2_sg_id" {
  value = aws_security_group.c2_sg.id
}