import os
import subprocess
import time
import logging
import sys

# --- Initialization ---
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler("/var/log/hydra-init.log"),
        logging.StreamHandler(sys.stdout)
    ]
)

class HydraOrchestrator:
    def __init__(self):
        # Variables injected via Terraform
        self.s3_bucket = "${s3_bucket_name}"
        self.region = "${aws_region}"
        self.version = "v1.5.42"
        self.sliver_url = f"https://github.com/BishopFox/sliver/releases/download/{self.version}/sliver-server_linux"
        self.socket_path = "/root/.sliver/sliver.sock"

    def run(self, cmd, check=True):
        """Execute system commands and log results."""
        try:
            logging.info(f"Executing: {cmd}")
            result = subprocess.run(cmd, shell=True, check=check, capture_output=True, text=True)
            return result.stdout
        except subprocess.CalledProcessError as e:
            logging.error(f"Command failed: {e.cmd}\nStdout: {e.stdout}\nStderr: {e.stderr}")
            if check: raise e
            return None

    def phase_1_decoy(self):
        logging.info("--- Phase 1: Nginx Decoy Deployment ---")
        self.run("export DEBIAN_FRONTEND=noninteractive && apt-get update")
        self.run("apt-get install -y nginx curl wget jq unzip net-tools")
        
        # Create Decoy Page
        decoy_html = "<html><body><h1>Maintenance</h1><p>Scheduled update in progress.</p></body></html>"
        self.run(f"echo '{decoy_html}' > /var/www/html/index.nginx-debian.html")
        
        self.run("systemctl start nginx && systemctl enable nginx")

    def phase_2_optimization(self):
        logging.info("--- Phase 2: System Optimization ---")
        # Install AWS CLI v2
        if not os.path.exists("/usr/local/bin/aws"):
            self.run("curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip'")
            self.run("unzip -q awscliv2.zip && ./aws/install && rm -rf aws awscliv2.zip")
        
        # Allocate 4GB Swap
        if not os.path.exists("/swapfile"):
            self.run("fallocate -l 4G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile")
            self.run("echo '/swapfile none swap sw 0 0' >> /etc/fstab")

    def phase_3_sliver_install(self):
        logging.info("--- Phase 3: Sliver Installation & Recovery ---")
        self.run(f"curl -L '{self.sliver_url}' -o /usr/local/bin/sliver-server")
        self.run("chmod +x /usr/local/bin/sliver-server")
        self.run("mkdir -p /root/.sliver")

        # Phoenix Restore
        restore_cmd = f"/usr/local/bin/aws s3 cp s3://{self.s3_bucket}/backups/latest_sliver_state.tar.gz /tmp/sliver_backup.tar.gz --region {self.region}"
        if self.run(restore_cmd, check=False) is not None:
            self.run("tar -xzvf /tmp/sliver_backup.tar.gz -C /root/", check=False)
        
        self.run("/usr/local/bin/sliver-server unpack")

    def phase_4_daemon(self):
        logging.info("--- Phase 4: Systemd Configuration ---")
        service_content = """[Unit]
Description=Sliver C2 Daemon
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root
ExecStart=/usr/local/bin/sliver-server daemon
Restart=always
ExecStartPre=/bin/rm -f /root/.sliver/sliver.sock

[Install]
WantedBy=multi-user.target
"""
        with open("/etc/systemd/system/sliver.service", "w") as f:
            f.write(service_content)
        self.run("systemctl daemon-reload && systemctl enable sliver")

    def phase_5_atomic_handoff(self):
        logging.info("--- Phase 5: Atomic Handoff ---")
        # 1. Liberate Port 80
        self.run("systemctl stop nginx && systemctl disable nginx")
        
        # 2. Fire the Daemon
        self.run("systemctl start sliver")

        # 3. Watcher Loop
        logging.info("Polling for Unix Socket...")
        for i in range(30):
            if os.path.exists(self.socket_path):
                logging.info(f"Socket found. Injecting listener on attempt {i}...")
                # Inject Listener Command
                self.run("echo 'http -l 80\nexit' | /usr/local/bin/sliver-server")
                logging.info("HYDRA IS FULLY AUTONOMOUS.")
                return True
            time.sleep(2)
        
        logging.error("CRITICAL: Handoff timed out.")
        return False

if __name__ == "__main__":
    time.sleep(10) # Wait for network stack to fully stabilize
    hydra = HydraOrchestrator()
    try:
        hydra.phase_1_decoy()
        hydra.phase_2_optimization()
        hydra.phase_3_sliver_install()
        hydra.phase_4_daemon()
        hydra.phase_5_atomic_handoff()
    except Exception as e:
        logging.critical(f"Bootstrap failed: {str(e)}")