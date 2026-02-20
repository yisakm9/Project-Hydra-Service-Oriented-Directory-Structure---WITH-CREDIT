# --- 1. AMI Lookup (Ubuntu 24.04 ARM64) ---
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- 2. Launch Template ---
# Defines the configuration of the C2 server
resource "aws_launch_template" "c2_template" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  # Security & Identity
  vpc_security_group_ids = var.security_group_ids
  
  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  # The "Brain" - Injects the script to install Docker/Sliver & Restore S3 Backup
  user_data = var.user_data_base64

  # Storage: Encrypted Root Volume
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  # Tagging for Cost Allocation
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "${var.project_name}-node"
      Project = var.project_name
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# --- 3. Auto Scaling Group ---
# Maintains exactly 1 instance, replacing it if it crashes or Spot is reclaimed
resource "aws_autoscaling_group" "c2_asg" {
  name                = "${var.project_name}-asg-${var.environment}"
  vpc_zone_identifier = var.subnet_ids
  
  # Capacity Constraints
  min_size         = 1
  max_size         = 1
  desired_capacity = 1

  # Integration with ALB
  target_group_arns = var.target_group_arns
  health_check_type = "ELB" # If ALB can't reach port 80, kill and replace instance
  health_check_grace_period = 300

  # Use Launch Template
  launch_template {
    id      = aws_launch_template.c2_template.id
    version = "$Latest"
  }

  # --- Spot Instance Strategy ---
  # This configures the ASG to use Spot Instances to save money.
  # If Spot is unavailable, it won't launch (to save budget), 
  # but you can add 'on_demand_base_capacity' if you want guaranteed uptime.
  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0   # 0 On-Demand (100% Spot)
      on_demand_percentage_above_base_capacity = 0   # 0% On-Demand
      spot_allocation_strategy                 = "price-capacity-optimized"
    }
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 0 # Allow 0 healthy during update (since max is 1)
    }
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }
}