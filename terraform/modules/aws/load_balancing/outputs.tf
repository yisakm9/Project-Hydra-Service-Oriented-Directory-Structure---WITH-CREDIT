output "alb_dns_name" {
  description = "The DNS name of the ALB (Origin for CloudFront)"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  value = aws_lb.main.arn
}

output "target_group_arn" {
  description = "ARN of the Target Group (Needed by ASG)"
  value       = aws_lb_target_group.c2_tg.arn
}