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
  
  # CRITICAL CHANGE: We DO NOT specify instance_type here.
  # The Auto Scaling Group will inject the type based on the Attributes below.
  # instance_type = var.instance_type 

  vpc_security_group_ids = var.security_group_ids
  
  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  user_data = var.user_data_base64

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = 30 # Kept your upgrade to 30GB
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

  # --- Spot Instance Strategy (Attribute-Based Selection) ---
  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0 # 100% Spot
      
      # "price-capacity-optimized" is the best modern strategy.
      # It balances "Likelihood of interruption" (Capacity) with "Cost" (Price).
      spot_allocation_strategy                 = "price-capacity-optimized"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.c2_template.id
        version            = "$Latest"
      }

      # --- DYNAMIC OVERRIDES (The Solution) ---
      # Instead of listing specific types, we define the "Shape" of the server we want.
      # AWS will pick the cheapest available instance that matches these rules.
      override {
        instance_requirements {
          # 1. CPU: Strictly 2 vCPUs (Matches t4g.large, c6g.large, etc.)
          vcpu_count {
            min = 2
            max = 2
          }

          # 2. RAM: Between 4GB (Medium) and 8GB (Large)
          # This allows fallback to t4g.medium/c6g.large if t4g.large is sold out.
          memory_mib {
            min = 4096 
            max = 8192 
          }

          # 3. Architecture: Must be ARM64 (Graviton) to match your AMI
          cpu_manufacturers = ["amazon-web-services"]
          
          # 4. Generation: Current generation only (avoids old, slow hardware)
          instance_generations = ["current"]
          
          # 5. Burstable: Allowed (Includes T-series)
          burstable_performance = "included"
        }
      }
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