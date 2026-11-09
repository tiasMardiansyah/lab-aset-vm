#!/usr/bin/env bash
set -euo pipefail

IP=192.168.56.10
DOMAINS="aset www api mail dev backup vpn staging"
BEGIN="# >>> lab-aset-vm >>>"
END="# <<< lab-aset-vm <<<"
HOSTS=/etc/hosts

[ "$(id -u)" -eq 0 ] || { echo "Jalankan dengan sudo: sudo bash install.sh" >&2; exit 1; }

sed -i.bak "/^${BEGIN}$/,/^${END}$/d" "$HOSTS"
rm -f "${HOSTS}.bak"

{
  echo ""
  echo "$BEGIN"
  for d in $DOMAINS; do printf '%s\t%s.lab.local\n' "$IP" "$d"; done
  echo "$END"
} >> "$HOSTS"

echo "Hosts entries ditambahkan:"
for d in $DOMAINS; do echo "  $IP  $d.lab.local"; done
echo ""
echo "Jalankan: vagrant up"
