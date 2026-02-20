locals {
  project_name = "hydra"
  environment  = "production"
}

# --- 1. Foundation: Networking ---
module "networking" {
  source = "../../modules/aws/networking"

  project_name = local.project_name
  environment  = local.environment
  aws_region   = var.aws_region
}

# --- 2. The Vault: Storage (S3) ---
module "storage" {
  source = "../../modules/aws/storage"

  project_name = local.project_name
  environment  = local.environment
}

# --- 3. The Bridge: Messaging (SQS) ---
module "messaging" {
  source = "../../modules/aws/messaging"

  project_name = local.project_name
  environment  = local.environment
}

# --- 4. Identity: IAM ---
module "iam" {
  source = "../../modules/aws/iam"

  project_name  = local.project_name
  environment   = local.environment
  s3_bucket_arn = module.storage.bucket_arn
  sqs_queue_arn = module.messaging.task_queue_arn
}

# --- 5. The Firewall: Security Groups ---
module "security" {
  source = "../../modules/aws/security"

  project_name = local.project_name
  environment  = local.environment
  vpc_id       = module.networking.vpc_id
  my_ip        = var.my_ip
}

# --- 6. The Face: Load Balancing (ALB) ---
module "load_balancing" {
  source = "../../modules/aws/load_balancing"

  project_name    = local.project_name
  environment     = local.environment
  vpc_id          = module.networking.vpc_id
  public_subnets  = module.networking.public_subnet_ids
  security_groups = [module.security.alb_sg_id]
}

# --- 7. The Mask: CDN (CloudFront) ---
module "cdn" {
  source = "../../modules/aws/cdn"

  project_name       = local.project_name
  environment        = local.environment
  origin_domain_name = module.load_balancing.alb_dns_name
}

# --- 8. The Brain: User Data Injection ---
# We read the shell script template and fill in the placeholders
data "template_file" "user_data" {
  template = file("${path.module}/../../../resources/templates/user_data.tftpl")

  vars = {
    s3_bucket_name = module.storage.bucket_name
    aws_region     = var.aws_region
    sqs_task_url   = module.messaging.task_queue_url
  }
}

# --- 9. The Engine: Compute (ASG) ---
module "autoscaling" {
  source = "../../modules/aws/autoscaling"

  project_name              = local.project_name
  environment               = local.environment
  vpc_id                    = module.networking.vpc_id
  subnet_ids                = module.networking.public_subnet_ids
  security_group_ids        = [module.security.c2_sg_id]
  target_group_arns         = [module.load_balancing.target_group_arn]
  iam_instance_profile_name = module.iam.instance_profile_name
  user_data_base64          = base64encode(data.template_file.user_data.rendered)
  instance_type             = "t4g.large"
}