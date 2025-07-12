#!/bin/bash
set -e
echo "=== Startup script started at $(date) ==="
# Install dependencies
apt-get update -y
apt-get install -y curl lsb-release

# Install cloudflared
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
dpkg -i cloudflared.deb
rm cloudflared.deb

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

# Install n8n
npm install -g n8n

# Configure n8n
mkdir -p /opt/n8n
useradd -r -d /opt/n8n -s /bin/false n8n
chown -R n8n:n8n /opt/n8n

cat > /etc/systemd/system/n8n.service <<EOF
[Unit]
Description=n8n
Requires=network.target
After=network.target

[Service]
Type=simple
User=n8n
Group=n8n
WorkingDirectory=/opt/n8n
ExecStart=/usr/bin/n8n start
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Configure cloudflared
# Create the configuration file that tells cloudflared what to do.
# The service will run `cloudflared tunnel run` and read this file.
mkdir -p /etc/cloudflared/
cat > /etc/cloudflared/config.yml << EOF
tunnel: ${tunnel_id}
credentials-file: /root/.cloudflared/${tunnel_id}.json
ingress:
  - hostname: ${domain}
    service: http://127.0.0.1:5678
  - service: http_status:404
EOF

# Fetch the token from secret manager
CLOUDFLARE_TOKEN=$(gcloud secrets versions access latest --secret="${secret_id}")

# Use the official command to install the service.
# This handles creating the systemd file and embedding the token.
cloudflared service install $CLOUDFLARE_TOKEN --config /etc/cloudflared/config.yml

# Start services
systemctl start cloudflared
systemctl enable cloudflared
systemctl start n8n
systemctl enable n8n
echo "=== Startup script completed at $(date) ==="
