# =============================================================================
# PROJECT HYDRA: GCP CONFIGURATION
# =============================================================================
# WARNING: This file contains secrets. It is .gitignore'd.
# Populate these values locally or via CI/CD secrets.

# GCP
gcp_project_id = "web-analytics-prod-491408" # Your GCP Project ID
gcp_region     = "us-central1"
gcp_zone       = "us-central1-f"
my_ip          = "196.188.180.92/32" # Your IP in CIDR format, e.g. "1.2.3.4/32"

# Cloudflare
cloudflare_api_token  = "cfut_hdNz76w9PjLINBbabLpzEwdCUrzt2OqZw3m3AocDd10412f5" # Cloudflare API token
cloudflare_account_id = "c49e530cae07dd293ebec40c34b39364"                      # Cloudflare Account ID
cloudflare_zone_id    = "1fed12ab8cd7842291255d6a9dda996d"                      # Zone ID for googleupdate.uk

# SSH (public key content, not path)
public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE+cb3wnfTvDjiKNNAwrKqTKJscsddrWh5rvLzuep8Fb hydra@c2" # ssh-ed25519 AAAA... user@host
