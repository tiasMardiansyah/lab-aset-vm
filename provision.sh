#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

apt update
apt install -y nodejs npm dnsutils bind9 bind9utils

# Deploy app files
mkdir -p /var/www/aset-lab
cp /opt/aset-app/server.js /var/www/aset-lab/server.js
cp /opt/aset-app/robots.txt /var/www/aset-lab/robots.txt
cp /opt/aset-app/sitemap.xml /var/www/aset-lab/sitemap.xml

# Run as a systemd service (auto-restart, boots with VM)
cat > /etc/systemd/system/aset-web.service <<EOF
[Unit]
Description=Aset Lab Web Server
After=network.target

[Service]
ExecStart=/usr/bin/node /var/www/aset-lab/server.js
Restart=always
User=nobody
Environment=PORT=8080
WorkingDirectory=/var/www/aset-lab

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now aset-web

# --- DNS setup (BIND9) ---
# Get this VM's actual bridged IP dynamically (enp0s8)
TARGET_IP=$(ip -4 addr show enp0s8 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

# Free up port 53: disable systemd-resolved's stub listener (drop-in is more reliable than sed)
mkdir -p /etc/systemd/resolved.conf.d
cat > /etc/systemd/resolved.conf.d/nostub.conf <<EOF
[Resolve]
DNSStubListener=no
EOF
systemctl restart systemd-resolved

# Stop dnsmasq if present: it was holding TCP/53 and blocking named
systemctl disable --now dnsmasq 2>/dev/null || true
pkill dnsmasq 2>/dev/null || true

# Zone declaration
cat > /etc/bind/named.conf.local <<EOF
zone "lab.local" {
    type master;
    file "/etc/bind/db.lab.local";
    allow-transfer { any; };   // intentionally permissive — simulates a vulnerable AXFR config
};
EOF

# Zone file with dynamically resolved IP
cat > /etc/bind/db.lab.local <<EOF
\$TTL    600
@       IN      SOA     aset.lab.local. admin.lab.local. (
                        1         ; Serial
                        3600      ; Refresh
                        1800      ; Retry
                        1209600   ; Expire
                        600 )     ; Negative Cache TTL

        IN      NS      aset.lab.local.

aset         IN      A      ${TARGET_IP}
www          IN      A      ${TARGET_IP}
api          IN      A      ${TARGET_IP}
mail         IN      A      ${TARGET_IP}
dev          IN      A      ${TARGET_IP}
backup       IN      A      ${TARGET_IP}
vpn          IN      A      ${TARGET_IP}
staging      IN      A      ${TARGET_IP}
EOF

# named.conf.options with listen-on inside the options block
cat > /etc/bind/named.conf.options <<EOF
options {
        directory "/var/cache/bind";

        listen-on { 127.0.0.1; ${TARGET_IP}; };

        recursion no;

        dnssec-validation no;

        listen-on-v6 { none; };
};
EOF

named-checkconf
named-checkzone lab.local /etc/bind/db.lab.local

systemctl restart named
systemctl enable named

echo "============================================="
echo "Aset Lab Web Server is running on port 8080"
echo "DNS (BIND9) running at: ${TARGET_IP}"
echo "Check: curl http://${TARGET_IP}:8080/health"
echo "Check DNS: dig aset.lab.local @${TARGET_IP}"
echo "Check AXFR: dig AXFR lab.local @${TARGET_IP}"
echo "============================================="