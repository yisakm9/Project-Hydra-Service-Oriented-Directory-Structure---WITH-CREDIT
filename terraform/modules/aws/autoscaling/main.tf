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
resource "aws_launch_template" "c2_template" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  vpc_security_group_ids = var.security_group_ids
  
  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  user_data = var.user_data_base64

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = 30 # Increased to 30GB for larger log/loot storage
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

  # --- Spot Instance Strategy: "The Shotgun" ---
  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0 # 100% Spot
      
      # "price-capacity-optimized" is the BEST strategy for finding capacity.
      # It ignores the cheapest option if it's likely to be interrupted.
      spot_allocation_strategy                 = "price-capacity-optimized" 
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.c2_template.id
        version            = "$Latest"
      }

      # --- OVERRIDES: The expanded probability pool ---
      
      # 1. Primary Target (Burstable, 8GB RAM)
      override { instance_type = "t4g.large" }

      # 2. General Purpose (Standard, 8GB RAM)
      override { instance_type = "m6g.large" }
      override { instance_type = "m7g.large" } # Newer gen

      # 3. Memory Optimized (16GB RAM - Often very cheap on Spot!)
      override { instance_type = "r6g.large" }
      override { instance_type = "r7g.large" }

      # 4. Compute Optimized (4GB RAM - Robust availability)
      # We have Swap enabled, so 4GB is safe for Sliver.
      override { instance_type = "c6g.large" }
      override { instance_type = "c7g.large" }

      # 5. Failsafe (Smallest acceptable size)
      override { instance_type = "t4g.medium" }
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