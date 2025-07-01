#!/bin/bash
set -e
echo "=== Startup script started at $(date) ==="
apt-get update -y
apt-get install -y nginx
systemctl start nginx
systemctl enable nginx
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
dpkg -i cloudflared-linux-amd64.deb
mkdir -p /etc/cloudflared/
cat > /etc/cloudflared/config.yml << EOF
tunnel: <MY_TUNNEL_ID>
credentials-file: /root/.cloudflared/<MY_TUNNEL_ID>.json
ingress:
  - hostname: nginx.<MY_DOMAIN>
    service: http://127.0.0.1:80
  - service: http_status:404
EOF
cloudflared service install <MY_TUNNEL_TOKEN> --config /etc/cloudflared/config.yml
systemctl start cloudflared
systemctl enable cloudflared
echo "=== Startup script completed at $(date) ==="