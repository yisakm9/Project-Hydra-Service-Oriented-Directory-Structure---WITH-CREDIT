# =============================================================================
# PROJECT HYDRA: GCP CONFIGURATION
# =============================================================================
# WARNING: This file contains secrets. It is .gitignore'd.
# Populate these values locally or via CI/CD secrets.

# GCP
gcp_project_id = ""        # Your GCP Project ID
gcp_region     = "us-central1"
gcp_zone       = "us-central1-a"
my_ip          = ""        # Your IP in CIDR format, e.g. "1.2.3.4/32"

# Cloudflare
cloudflare_api_token  = "" # Cloudflare API token
cloudflare_account_id = "" # Cloudflare Account ID
cloudflare_zone_id    = "" # Zone ID for googleupdate.uk

# SSH (public key content, not path)
public_key = ""            # ssh-ed25519 AAAA... user@host