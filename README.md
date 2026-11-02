# Lab Aset VM

Environment lab fiktif untuk latihan enumeration/recon: satu web server Node.js
(port 8080) + DNS server BIND9 dengan konfigurasi sengaja rentan (AXFR terbuka).

**Semua data di sini fiktif.** Jangan pakai konfigurasi ini di produksi.

## Isi Project

| File | Fungsi |
|------|--------|
| `Vagrantfile` | Definisikan VM Ubuntu 22.04 (jammy64), 2 GB RAM, 2 CPU |
| `provision.sh` | Install Node.js, BIND9, deploy app, buat service systemd & zone DNS |
| `app/server.js` | Web server (endpoint: `/`, `/api/pegawai`, `/api/produk`, `/health`, `/robots.txt`, `/sitemap.xml`) |
| `app/robots.txt` | Disallow `/api/pegawai` dan `/admin-backup/` (petunjuk buat recon) |
| `app/sitemap.xml` | Bocorkan path `/admin-backup/` dan `/old-portal/` |

## Prasyarat

- [VirtualBox](https://www.virtualbox.org/wiki/Downloads) 7.x
- [Vagrant](https://developer.hashicorp.com/vagrant/downloads) 2.4+
- Host dengan minimal 4 GB RAM kosong
- Windows/macOS/Linux (contoh di bawah pakai terminal Git Bash / bash)

Cek instalasi:

```bash
vagrant --version
vboxmanage --version
```

## 1. Jalankan VM

```bash
cd lab-aset-vm
vagrant up
```

VM akan otomatis di-provision (install paket + start service). Proses pertama
bisa 5–15 menit tergantung koneksi.

> **Penting:** `Vagrantfile` memakai `public_network` (bridged). Vagrant akan
> tanya interface mana yang mau dipakai. Pilih interface yang terhubung ke
> jaringan lab/Kali kamu (misal `1) Ethernet`, `2) Wi-Fi`). Kalau ragu, lihat
> nama adapter di host.

**Alternatif tanpa bridge** (jaringan host-only, lebih aman untuk coursework):
edit `Vagrantfile`, komentari baris `public_network`, aktifkan baris ini:

```ruby
config.vm.network "private_network", ip: "192.168.56.10"
```

lalu `vagrant reload --provision`. IP VM jadi tetap `192.168.56.10`.

## 2. Cek Status & Ambil IP

```bash
vagrant status
vagrant ssh -c "ip -4 addr show enp0s8"
```

IP ada di baris `inet` (misal `192.168.1.55`). Simpan sebagai `$VM_IP`:

```bash
VM_IP=192.168.1.55   # ganti dengan hasil di atas
```

## 3. Verifikasi Service

```bash
# Web server
curl http://$VM_IP:8080/health
curl http://$VM_IP:8080/api/pegawai

# DNS
dig aset.lab.local @$VM_IP
dig www.lab.local @$VM_IP

# Zone transfer (sengaja terbuka — ini target latihan)
dig AXFR lab.local @$VM_IP
```

Output `AXFR` harus menampilkan semua record (`aset`, `www`, `api`, `mail`,
`dev`, `backup`, `vpn`, `staging`) yang semuanya menunjuk ke IP VM yang sama.

## 4. Skenario Latihan (dari mesin Kali/attacker)

```bash
# Recon web
curl http://$VM_IP:8080/robots.txt        # bocorkan /api/pegawai & /admin-backup/
curl http://$VM_IP:8080/sitemap.xml       # bocorkan /admin-backup/ & /old-portal/
curl http://$VM_IP:8080/api/produk

# Enumeration DNS
nmap -sV -p 8080,53 $VM_IP
dig AXFR lab.local @$VM_IP
dnsrecon -d lab.local -n $VM_IP
```

Subdomain hasil AXFR (`dev`, `backup`, `vpn`, `staging`) belum punya service
terpisah — semuanya mengarah ke VM yang sama, jadi hasil recon tetap jujur
terhadap satu target.

## 5. Melihat Log

```bash
vagrant ssh
sudo journalctl -u aset-web -f          # log web server (akses tercatat)
sudo journalctl -u named -f             # log BIND9
```

## 6. Perintah Sehari-hari

| Perintah | Fungsi |
|----------|--------|
| `vagrant up` | Nyalakan (atau buat) VM |
| `vagrant halt` | Matikan VM (state disimpan) |
| `vagrant reload --provision` | Restart + jalankan ulang provision |
| `vagrant provision` | Jalankan ulang `provision.sh` tanpa reboot |
| `vagrant ssh` | Masuk ke VM |
| `vagrant destroy -f` | Hapus VM total (semua perubahan hilang) |

Kalau ubah `app/server.js`, jalankan ulang provision supaya file ter-copy ke
`/var/www/aset-lab` lalu restart service:

```bash
vagrant provision
vagrant ssh -c "sudo systemctl restart aset-web"
```

## Troubleshooting

**`vagrant up` minta pilih interface berulang / salah interface**
Jalankan `vagrant destroy -f` lalu `vagrant up` lagi dan pilih nomor interface
yang benar. Nama interface host bisa dilihat dengan `ipconfig` (Windows) atau
`ip a` (Linux/macOS).

**Provision gagal di bagian BIND / `TARGET_IP` kosong**
Berarti interface `enp0s8` tidak ada. Cek `vagrant ssh -c "ip -4 addr"`. Kalau
bridge gagal, pakai opsi `private_network` di langkah 1 (IP jadi `192.168.56.10`).

**`dig ... @$VM_IP` timeout**
- Pastikan IP benar dan satu segmen jaringan dengan host.
- Cek service: `vagrant ssh -c "sudo systemctl status named"`.
- Firewall host (Windows Defender) bisa memblokir traffic masuk ke VM; izinkan
  VirtualBox atau coba dari dalam VM dulu: `vagrant ssh -c "dig aset.lab.local @127.0.0.1"`.

**Port 8080 sudah dipakai di host**
Tidak masalah — port 8080 ada di dalam VM, bukan host. Konflik hanya terjadi
kalau ada service lain di VM yang sama.

**VM lambat / RAM kurang**
Edit `Vagrantfile`: naikkan `vb.memory` (misal `"4096"`), lalu
`vagrant reload`.

## Peringatan

Konfigurasi ini **sengaja tidak aman** (`allow-transfer { any; }`,
`dnssec-validation no`, `recursion no`, data palsu di endpoint publik) untuk
keperluan pembelajaran. Jangan jalankan di jaringan produksi atau jaringan
publik tanpa isolasi.
