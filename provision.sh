#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

apt update
apt install -y nodejs npm mysql-server dnsutils bind9 bind9utils

# --- MySQL setup ---
systemctl enable --now mysql

mysql <<'EOF'
CREATE DATABASE IF NOT EXISTS aset_lab;
CREATE USER IF NOT EXISTS 'aset'@'localhost' IDENTIFIED BY 'aset';
GRANT SELECT ON aset_lab.* TO 'aset'@'localhost';

CREATE TABLE IF NOT EXISTS aset_lab.users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  password CHAR(32) NOT NULL
);

CREATE TABLE IF NOT EXISTS aset_lab.pegawai (
  id INT PRIMARY KEY,
  nama VARCHAR(100) NOT NULL,
  role VARCHAR(50) NOT NULL,
  email VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS aset_lab.produk (
  kode VARCHAR(20) PRIMARY KEY,
  nama VARCHAR(100) NOT NULL,
  stok INT NOT NULL,
  harga BIGINT NOT NULL
);

INSERT IGNORE INTO aset_lab.users (username, password) VALUES
  ('admin', MD5('admin123')),
  ('tias',  MD5('rahasia123'));

INSERT IGNORE INTO aset_lab.pegawai (id, nama, role, email) VALUES
  (1, 'Tias',   'It',         'tias@contoh.test'),
  (2, 'Dicky',  'Finance',    'dicky@contoh.test'),
  (3, 'Roland', 'StafGudang', 'roland@contoh.test');

INSERT IGNORE INTO aset_lab.produk (kode, nama, stok, harga) VALUES
  ('P-001', 'Thinkpad P53',           12, 8500000),
  ('P-002', 'Thinkpad T14 G1 Intel',  40, 5600000),
  ('P-003', 'Thinkpad T14 G2 AMD',     7, 6500000);
EOF

# Deploy app files
mkdir -p /var/www/aset-lab
cp /opt/aset-app/server.js /var/www/aset-lab/server.js
cp /opt/aset-app/db.js /var/www/aset-lab/db.js
cp /opt/aset-app/views.js /var/www/aset-lab/views.js
cp /opt/aset-app/robots.txt /var/www/aset-lab/robots.txt
cp /opt/aset-app/sitemap.xml /var/www/aset-lab/sitemap.xml
cp /opt/aset-app/package.json /var/www/aset-lab/package.json

# Install app dependencies (mysql2)
cd /var/www/aset-lab
npm install --no-audit --no-fund

# Run as a systemd service (auto-restart, boots with VM)
cat > /etc/systemd/system/aset-web.service <<EOF
[Unit]
Description=Aset Lab Web Server
After=network.target mysql.service

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

        allow-query { any; };

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