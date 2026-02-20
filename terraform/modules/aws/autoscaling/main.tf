# --- 1. AMI Lookup (Ubuntu 24.04 x86_64/AMD64) ---
# Required for m7i-flex and c7i-flex instances
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
  instance_type = "m7i-flex.large" # 8GB RAM Primary Choice
  key_name = var.ssh_key_name
  vpc_security_group_ids = var.security_group_ids
  
  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  user_data = var.user_data_base64

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = 25 # Increased to 25GB for better performance
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
  health_check_grace_period = 1200

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 1 # Force at least 1 On-Demand to bypass Spot issues
      on_demand_percentage_above_base_capacity = 100
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.c2_template.id
        version            = "$Latest"
      }

      # --- High-Performance "Free Tier" Eligible Overrides ---
      
      # 1. Primary: 8GB RAM
      override { instance_type = "m7i-flex.large" } 
      
      # 2. Secondary: 4GB RAM
      override { instance_type = "c7i-flex.large" } 
      
      
      
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