# Project Hydra: Service-Oriented C2 Infrastructure (GCP Edition)

Project Hydra is a highly resilient, automated, and secure Command and Control (C2) infrastructure deployment built around **Mythic C2** on **Google Cloud Platform (GCP)**. 

Designed for Senior Red Team engagements, this architecture prioritizes operational security (OpSec), high availability, automated infrastructure-as-code (IaC), and seamless C2 traffic obfuscation.

---

## 🏗️ Architecture Overview

The infrastructure relies entirely on GCP-native services and Cloudflare to obscure the true origin of the C2 server. 

### Traffic Flow (OpSec Chain)
1. **Victim Payload** calls out to `https://googleupdate.uk` (Cloudflare).
2. **Cloudflare Worker** (`ghost_proxy.js`) intercepts the request, scrubs tracking headers, and forwards traffic to the GCP Load Balancer.
3. **GCP External HTTP Load Balancer** receives the request, utilizing Cloud CDN (configured for pass-through/zero-cache).
4. **Nginx Reverse Proxy** on the C2 instance intercepts the request on Port `80`, answering LB Health Checks directly, while silently proxying payload traffic to `http://127.0.0.1:8181`.
5. **Mythic HTTP C2 Profile** processes the request internally on port `8181`.

### Key Components
*   **Compute**: Managed Instance Group (MIG) running an `e2-standard-2` machine. The MIG guarantees `target_size = 1`. If the instance fails or the underlying template updates, the auto-healer provisions a fresh node automatically.
*   **Phoenix Strategy**: Fully automated bootstrap (`user_data.tftpl`) installs Docker, builds Mythic, and generates C2 profiles dynamically on boot. 
*   **Storage**: GCS bucket with object versioning for Terraform State and Phoenix backups.
*   **Security**: 
    *   Ephemeral external IP (No NAT) to minimize costs.
    *   Strict GCP Firewall rules (SSH and UI restricted to Admin IP).
    *   Google-managed disk encryption.
*   **Messaging**: Cloud Pub/Sub for automated tasking and deployment hooks.

---

## 🔒 CI/CD Pipeline & Keyless Auth

This repository uses **GitHub Actions** for continuous deployment, operating entirely via **GCP Workload Identity Federation (WIF)**. 

**No long-lived JSON service account keys are stored in GitHub.**

### Workflows
*   `deploy.yml`: Lints Terraform, executes `tfsec` security scans, runs `terraform plan`, and automatically applies on pushes to the `main` branch.
*   `destroy.yml`: Safely tears down the infrastructure using the WIF credentials.
*   `unlock.yml`: Force-unlocks the GCS Terraform state if a pipeline fails unexpectedly.

---

## 🚀 Deployment Guide

### Prerequisites
1. A Google Cloud Project.
2. `gcloud` CLI installed and authenticated.
3. A Cloudflare account with a registered domain (e.g., `googleupdate.uk`) and an API Token.

### Step 1: Pre-Deployment Setup
Initialize the remote state bucket in your GCP project:
```bash
gsutil mb -p YOUR_PROJECT_ID -l us-central1 gs://hydra-terraform-state-unique-id
gsutil versioning set on gs://hydra-terraform-state-unique-id
```
*(Update `terraform/live/production/provider.tf` with your unique bucket name).*

### Step 2: Configure Variables
Populate `terraform.tfvars` (in `terraform/live/production/`) with your secrets:
```hcl
gcp_project_id        = "your-project-id"
gcp_region            = "us-central1"
gcp_zone              = "us-central1-f"
my_ip                 = "YOUR_IP/32"
cloudflare_api_token  = "..."
cloudflare_account_id = "..."
cloudflare_zone_id    = "..."
public_key            = "ssh-ed25519 AAAA..."
```

### Step 3: CI/CD Setup
Set up the Workload Identity Pool and connect it to your GitHub repository. Export the WIF credentials to your GitHub Secrets:
*   `GCP_PROJECT_ID`
*   `GCP_WIF_PROVIDER`
*   `GCP_WIF_SERVICE_ACCOUNT`
*   `CLOUDFLARE_API_TOKEN`
*   `CLOUDFLARE_ACCOUNT_ID`
*   `CLOUDFLARE_ZONE_ID`
*   `SSH_PUBLIC_KEY`
*   `ADMIN_IP_CIDR`

### Step 4: Deploy & Access Mythic
Once GitHub Actions has applied the Terraform (or you run it locally), the Mythic C2 instance takes approximately **20–25 minutes** to fully bootstrap, install Docker, compile the Apollo agent, and launch its web UI.
1. SSH into the node: `gcloud compute ssh hydra-node-xxx`
2. Retrieve the generated admin password: `cd /opt/Mythic && sudo ./mythic-cli config get MYTHIC_ADMIN_PASSWORD`
3. Access the UI: `https://<INSTANCE_IP>:7443`
4. **Important:** Change your HTTP Profile in Mythic to listen on **Port 8181** so Nginx can proxy C2 traffic to it.

---

## 🛡️ OpSec Considerations

*   **Cloudflare Header Scrubbing**: The `ghost_proxy.js` Cloudflare worker explicitly strips `X-Cloud-Trace-Context`, `Via`, and `Server` headers. To a passive observer, the C2 payload appears to be talking to a standard Cloudflare-backed generic site.
*   **Burn & Rebuild**: If the infrastructure is burned or flagged, a single `terraform destroy` and `terraform apply` will spin up a fresh instance with a new IP address, cleanly rebuilding Mythic from source.
*   **Admin Access Guard**: The GCP Firewall strictly locks SSH (`22`) and the Mythic UI (`7443`) to the `ADMIN_IP_CIDR`.

---
*Developed for advanced adversary emulation and Red Team operations.*
