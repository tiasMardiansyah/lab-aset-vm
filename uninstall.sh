#!/usr/bin/env bash
set -euo pipefail

BEGIN="# >>> lab-aset-vm >>>"
END="# <<< lab-aset-vm <<<"
HOSTS=/etc/hosts

[ "$(id -u)" -eq 0 ] || { echo "Jalankan dengan sudo: sudo bash uninstall.sh" >&2; exit 1; }

if grep -qxF "$BEGIN" "$HOSTS"; then
  sed -i.bak "/^${BEGIN}$/,/^${END}$/d" "$HOSTS"
  rm -f "${HOSTS}.bak"
  echo "Entri lab-aset-vm dihapus dari hosts."
else
  echo "Tidak ada entri lab-aset-vm di hosts — tidak ada yang dihapus."
fi
