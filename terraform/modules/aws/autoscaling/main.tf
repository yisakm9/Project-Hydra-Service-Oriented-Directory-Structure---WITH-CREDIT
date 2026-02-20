# --- 1. AMI Lookup (Ubuntu 24.04 x86_64/AMD64) ---
# Switching to x86 to avoid ARM-specific Free Tier promotion conflicts
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- 2. Launch Template ---
resource "aws_launch_template" "c2_template" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.medium" # 2 vCPU, 4GB RAM (Standard x86)

  vpc_security_group_ids = var.security_group_ids
  
  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  user_data = var.user_data_base64

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

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
resource "aws_autoscaling_group" "c2_asg" {
  name                = "${var.project_name}-asg-${var.environment}"
  vpc_zone_identifier = var.subnet_ids
  
  min_size         = 1
  max_size         = 1
  desired_capacity = 1

  target_group_arns         = var.target_group_arns
  health_check_type         = "ELB"
  health_check_grace_period = 300

  # --- HYBRID RECOVERY STRATEGY ---
  mixed_instances_policy {
    instances_distribution {
      # Try to get Spot first (0 On-Demand base)
      on_demand_base_capacity                  = 0
      
      # Percentage of On-Demand if Spot fails
      # We set this to 0 to prioritize Spot, but 'capacity-optimized' 
      # will allow the ASG to look for any available pool.
      on_demand_percentage_above_base_capacity = 0
      
      # Capacity-Optimized: This is the secret for Spot success. 
      # It picks the instance pool with the most available capacity.
      spot_allocation_strategy = "capacity-optimized" 
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.c2_template.id
        version            = "$Latest"
      }

      # List of instances that usually bypass the "Free Tier Only" filter
      override { instance_type = "t3.medium" } # 4GB RAM
      override { instance_type = "t3.small" }  # 2GB RAM (Last Resort)
      override { instance_type = "c5.large" }  # Compute-heavy (Often high Spot availability)
    }
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 0
    }
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }
}