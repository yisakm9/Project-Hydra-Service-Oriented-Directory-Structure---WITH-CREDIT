# ==============================================================================
# 0. GLOBALS & LOCALS
# ==============================================================================
locals {
  project_name = "hydra"
  environment  = "production"

}

# ==============================================================================
# 1. SECURITY: SSH KEY MANAGEMENT
# ==============================================================================
# Using a random suffix to prevent "Duplicate KeyPair" errors in AWS
resource "random_id" "key_suffix" {
  byte_length = 4
}

resource "aws_key_pair" "kp" {
  key_name   = "${local.project_name}-key-${random_id.key_suffix.hex}"
  public_key = var.public_key # Uses the secret from GitHub Actions
}

# ==============================================================================
# 2. CORE INFRASTRUCTURE MODULES
# ==============================================================================

module "networking" {
  source       = "../../modules/aws/networking"
  project_name = local.project_name
  environment  = local.environment
  aws_region   = var.aws_region
}

module "storage" {
  source       = "../../modules/aws/storage"
  project_name = local.project_name
  environment  = local.environment
}

module "messaging" {
  source       = "../../modules/aws/messaging"
  project_name = local.project_name
  environment  = local.environment
}

module "iam" {
  source        = "../../modules/aws/iam"
  project_name  = local.project_name
  environment   = local.environment
  s3_bucket_arn = module.storage.bucket_arn
  sqs_queue_arn = module.messaging.task_queue_arn
}

module "security" {
  source       = "../../modules/aws/security"
  project_name = local.project_name
  environment  = local.environment
  vpc_id       = module.networking.vpc_id
  my_ip        = var.my_ip
}

# ==============================================================================
# 3. TRAFFIC DELIVERY (ALB & CLOUDFRONT)
# ==============================================================================

module "load_balancing" {
  source          = "../../modules/aws/load_balancing"
  project_name    = local.project_name
  environment     = local.environment
  vpc_id          = module.networking.vpc_id
  public_subnets  = module.networking.public_subnet_ids
  security_groups = [module.security.alb_sg_id]
}

module "cdn" {
  source             = "../../modules/aws/cdn"
  project_name       = local.project_name
  environment        = local.environment
  origin_domain_name = module.load_balancing.alb_dns_name
}

# ==============================================================================
# 4. COMPUTE & AUTOMATION (ASG)
# ==============================================================================

# Final rendering of the User Data wrapper
data "template_file" "user_data" {
  template = file("${path.module}/../../../resources/templates/user_data.tftpl")

  vars = {
    s3_bucket_name = module.storage.bucket_name
    aws_region     = var.aws_region
  }
}

module "autoscaling" {
  source                    = "../../modules/aws/autoscaling"
  project_name              = local.project_name
  environment               = local.environment
  vpc_id                    = module.networking.vpc_id
  subnet_ids                = module.networking.public_subnet_ids
  security_group_ids        = [module.security.c2_sg_id]
  target_group_arns         = [module.load_balancing.target_group_arn]
  iam_instance_profile_name = module.iam.instance_profile_name
  ssh_key_name              = aws_key_pair.kp.key_name
  instance_type             = "m7i-flex.large"
  
  # Base64 encode the final rendered bootstrap
  user_data_base64          = base64encode(data.template_file.user_data.rendered)
}