# --- 1. The Application Load Balancer ---
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb-${var.environment}"
  internal           = false # Internet Facing
  load_balancer_type = "application"
  security_groups    = var.security_groups
  subnets            = var.public_subnets

  enable_deletion_protection = false # Set to true for real production

  tags = {
    Name = "Hydra-ALB"
  }
}

# --- 2. Target Group ---
# The ALB forwards traffic here. The ASG will attach instances to this group.
resource "aws_lb_target_group" "c2_tg" {
  name     = "${var.project_name}-tg-${var.environment}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  # Health Check: Ensures the C2 is actually running before sending traffic
  health_check {
    enabled             = true
    path                = "/" # Ensure Sliver is configured to respond here or change path
    protocol            = "HTTP"
    matcher             = "200-499" # Accept any response code indicating the server is alive
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    port                = "80" # Explicitly check port 80
  }
}

# --- 3. Listener (HTTP) ---
# Since we don't have a domain for ACM, we listen on HTTP 80.
# CloudFront will handle the HTTPS on the front end.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.c2_tg.arn
  }
}