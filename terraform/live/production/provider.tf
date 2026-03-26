terraform {
  required_version = ">= 1.13.1"

  backend "gcs" {
    bucket = "hydra-tfstate-ab6b9368"
    prefix = "hydra/production/terraform.tfstate"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
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
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone

  default_labels = {
    project     = "hydra"
    environment = "production"
    managed_by  = "terraform"
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}