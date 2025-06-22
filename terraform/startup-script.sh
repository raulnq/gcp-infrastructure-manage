#!/bin/bash
set -e
echo "=== Startup script started at $(date) ==="
apt-get update -y
apt-get install -y nginx
systemctl start nginx
systemctl enable nginx
echo "=== Startup script completed at $(date) ==="