# --- 1. Load Balancer Security Group ---
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg-${var.environment}"
  description = "Allow inbound HTTPS from CloudFront/Internet"
  vpc_id      = var.vpc_id

  # Inbound: Allow HTTPS (443) from anywhere (CloudFront connects here)
  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound: Allow HTTP (80) for redirect to HTTPS
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound: Allow traffic to the EC2 instances
  egress {
    description = "Outbound to EC2"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Hydra-ALB-SG"
  }
}

# --- 2. C2 Server (EC2) Security Group ---
resource "aws_security_group" "c2_sg" {
  name        = "${var.project_name}-ec2-sg-${var.environment}"
  description = "Security Group for Sliver C2 Nodes"
  vpc_id      = var.vpc_id

  # Inbound: Allow traffic ONLY from the ALB
  # This makes the EC2 invisible to port scanners on the public internet
  ingress {
    description     = "Traffic from ALB"
    from_port       = 80 # ALB terminates SSL, talks to EC2 on 80 or 8888
    to_port         = 80 # Sliver Listener Port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Inbound: Management (SSH) - Strictly limited to YOUR IP
  ingress {
    description = "SSH from Admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
# Inbound: Mythic Web UI - Strictly limited to YOUR IP
  ingress {
    description = "Mythic Web UI"
    from_port   = 7443
    to_port     = 7443
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
  # Outbound: Allow EC2 to talk to S3/SQS/Updates
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Hydra-EC2-SG"
  }
}