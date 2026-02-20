terraform {
  required_version = ">= 1.13.1"
  backend "s3" {
    bucket         = "ysak-terraform-state-bucket-red-team"
    key            = "hydra/dev/terraform.tfstate"
    region         = "us-east-1" 
    encrypt        = true
    use_lockfile   = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  
}
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "Hydra"
      Environment = "Dev"
      ManagedBy   = "Terraform"
    }
  }
}
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}