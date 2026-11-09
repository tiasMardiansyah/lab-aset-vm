# Lab Aset VM

Lab fiktif untuk latihan recon: web server Node.js + MySQL (port 8080) dan DNS
BIND9 dengan AXFR terbuka.

**Semua data fiktif. Konfigurasi ini sengaja tidak aman.**

## Topologi

| Mesin | Peran | Alamat |
|-------|-------|--------|
| Host Windows **atau** Linux | Jalankan VirtualBox + Vagrant, edit hosts | `192.168.56.1` (host-only) |
| VM Ubuntu 22.04 | Server lab (web + MySQL + BIND9) | `192.168.56.10` |
| Kali (opsional) | Mesin penyerang | host-only `192.168.56.0/24` |

Host boleh Windows atau Linux — langkah di bawah dipisah per OS.

## 1. Prasyarat

Aktifkan virtualisasi (VT-x/AMD-V) di BIOS sebelum mulai.

### Windows

```powershell
winget install --id Oracle.VirtualBox -e --accept-source-agreements --accept-package-agreements
winget install --id Hashicorp.Vagrant -e --accept-source-agreements --accept-package-agreements
```

Restart, buka PowerShell baru, lalu cek `vagrant --version` dan
`vboxmanage --version`.

### Linux (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install -y virtualbox vagrant
```

Untuk distro lain, pasang VirtualBox dan Vagrant dari repo resmi masing-masing.
Perlu logout/login (atau reboot) agar user masuk grup `vboxusers`.

Cek di kedua OS:

```bash
vagrant --version
vboxmanage --version
```

## 2. Setup per OS

### Windows

1. Klik kanan `install.bat` > **Run as administrator** — menambah entri
   `*.lab.local` ke `%WINDIR%\System32\drivers\etc\hosts`.
2. Nyalakan VM:

```bash
vagrant up
```

### Linux

1. Tambah entri hosts (butuh sudo):

```bash
sudo bash install.sh
```

2. Nyalakan VM:

```bash
vagrant up
```

Run pertama 5–15 menit (install Node, MySQL, BIND9, seed data).

### Uninstall hosts

- Windows: klik kanan `uninstall.bat` > **Run as administrator**.
- Linux: `sudo bash uninstall.sh`.

## 3. Verifikasi

```bash
curl http://192.168.56.10:8080/health
dig aset.lab.local @192.168.56.10
dig AXFR lab.local @192.168.56.10
```

Browser: `http://aset.lab.local:8080` → redirect ke halaman login.

## 4. Akun Lab

| User | Password |
|------|----------|
| admin | admin123 |
| tias | rahasia123 |

## 5. Latihan Recon (dari Kali di network yang sama)

```bash
curl http://192.168.56.10:8080/robots.txt
curl http://192.168.56.10:8080/sitemap.xml
curl -i http://192.168.56.10:8080/api/produk   # redirect ke /login
nmap -sV -p 8080,53,3306 192.168.56.10
dig AXFR lab.local @192.168.56.10
```

Kali yang berjalan sebagai VM di host yang sama perlu adapter host-only
tambahan di `192.168.56.0/24`.

## 6. Perintah

| Perintah | Fungsi |
|----------|--------|
| `vagrant up` / `halt` | Nyalakan / matikan VM |
| `vagrant provision` | Jalankan ulang `provision.sh` |
| `vagrant ssh` | Masuk ke VM |
| `vagrant destroy -f` | Hapus VM |

Setelah mengubah file di `app/`:

```bash
vagrant provision
vagrant ssh -c "sudo systemctl restart aset-web"
```

## 7. Log

```bash
vagrant ssh -c "sudo journalctl -u aset-web -f"
vagrant ssh -c "sudo journalctl -u named -f"
```

## 8. Troubleshooting

- **`dig` timeout dari host Windows** — izinkan `VBoxHeadless.exe` di Windows
  Firewall.
- **`dig` timeout dari host Linux** — cek `sudo ufw status`; izinkan traffic
  dari `192.168.56.0/24` bila firewall aktif.
- **`TARGET_IP` kosong** — cek `vagrant ssh -c "ip -4 addr"`, harus ada
  `192.168.56.10` di `enp0s8`.
- **VM lambat** — naikkan `vb.memory` di `Vagrantfile`, lalu `vagrant reload`.

## 9. Struktur

| File | Fungsi |
|------|--------|
| `Vagrantfile` | VM Ubuntu 22.04, IP `192.168.56.10` |
| `provision.sh` | Install Node, MySQL, BIND9 + seed data |
| `install.bat` / `install.ps1` | Tambah entri hosts Windows |
| `uninstall.bat` / `uninstall.ps1` | Hapus entri hosts Windows |
| `install.sh` / `uninstall.sh` | Tambah/hapus entri hosts Linux & macOS |
| `app/server.js` | Routing + auth (session cookie) |
| `app/db.js` | Koneksi MySQL + query |
| `app/views.js` | HTML halaman login & portal |
| `app/sitemap.xml`, `app/robots.txt` | Petunjuk path tersembunyi untuk recon |
