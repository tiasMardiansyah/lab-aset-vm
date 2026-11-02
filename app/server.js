const http = require('http');
const fs = require('fs');
const path = require('path');

// Data fiktif — representasi aset digital
const pegawai = [
  { id: 1, nama: 'Tias', role: 'It', email: 'tias@contoh.test' },
  { id: 2, nama: 'Dicky', role: 'Finance', email: 'dicky@contoh.test' },
  { id: 3, nama: 'Roland', role: 'StafGudang', email: 'roland@contoh.test' },
];

const produk = [
  { kode: 'P-001', nama: 'Thinkpad P53', stok: 12, harga: 8500000 },
  { kode: 'P-002', nama: 'Thinkpad T14 G1 Intel', stok: 40, harga: 5600000 },
  { kode: 'P-003', nama: 'Thinkpad T14 G2 AMD', stok: 7, harga: 6500000 },
];

const json = (res, code, data) => {
  res.writeHead(code, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(data, null, 2));
};

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  console.log(`${new Date().toISOString()} ${req.socket.remoteAddress} ${req.method} ${url.pathname}`);

  switch (url.pathname) {
    case '/':
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
      return res.end(
        `<!DOCTYPE html>
        <html lang="id"><head><meta charset="utf-8"><title>PT Kucing Tiga</title></head>
          <body>
            <h1>Portal Internal PT Kucing Tiga (FIKTIF)</h1>
            <ul>
                <li><a href="/api/pegawai">Data Pegawai</a></li>
                <li><a href="/api/produk">Data Produk</a></li>
                <li><a href="/health">Health Check</a></li>
            </ul>
          </body>
        </html>`
    );

    case '/robots.txt':
      res.writeHead(200, { 'Content-Type': 'text/plain' });
      return res.end(fs.readFileSync(path.join(__dirname, 'robots.txt')));
    case '/sitemap.xml':
      res.writeHead(200, { 'Content-Type': 'application/xml' });
      return res.end(fs.readFileSync(path.join(__dirname, 'sitemap.xml')));
    case '/api/pegawai':
      return json(res, 200, pegawai);
    case '/api/produk':
      return json(res, 200, produk);
    case '/health':
      return json(res, 200, { status: 'ok', waktu: new Date().toISOString() });
    default:
      return json(res, 404, { error: 'Tidak ditemukan' });
  }
});

const PORT = process.env.PORT || 8080;
server.listen(PORT, '0.0.0.0', () => console.log(`Server berjalan di port ${PORT}`));