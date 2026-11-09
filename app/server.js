const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const db = require('./db');
const views = require('./views');

// ponytail: in-memory sessions, restart logs everyone out. Redis if that ever matters.
const sessions = new Map();

const json = (res, code, data) => {
  res.writeHead(code, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(data, null, 2));
};

const html = (res, code, body) => {
  res.writeHead(code, { 'Content-Type': 'text/html; charset=utf-8' });
  res.end(body);
};

const md5 = (s) => crypto.createHash('md5').update(s).digest('hex');

const getCookie = (req, name) => {
  const m = (req.headers.cookie || '').match(new RegExp(`(?:^|;\\s*)${name}=([^;]*)`));
  return m ? decodeURIComponent(m[1]) : null;
};

const readBody = (req) =>
  new Promise((resolve, reject) => {
    let data = '';
    req.on('data', (chunk) => {
      data += chunk;
      if (data.length > 1e5) req.destroy();
    });
    req.on('end', () => resolve(data));
    req.on('error', reject);
  });

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  console.log(`${new Date().toISOString()} ${req.socket.remoteAddress} ${req.method} ${url.pathname}`);

  try {
    if (url.pathname === '/login' && req.method === 'GET') {
      return html(res, 200, views.loginPage());
    }

    if (url.pathname === '/login' && req.method === 'POST') {
      const form = new URLSearchParams(await readBody(req));
      const user = await db.findUser(form.get('username') || '', md5(form.get('password') || ''));
      if (!user) return html(res, 401, views.loginPage('Username atau password salah'));

      const token = crypto.randomBytes(24).toString('hex');
      sessions.set(token, user.username);
      res.writeHead(302, { 'Set-Cookie': `session=${token}; HttpOnly; Path=/`, Location: '/' });
      return res.end();
    }

    if (url.pathname === '/logout') {
      const token = getCookie(req, 'session');
      if (token) sessions.delete(token);
      res.writeHead(302, { 'Set-Cookie': 'session=; Max-Age=0; Path=/', Location: '/login' });
      return res.end();
    }

    const isPublic = ['/health', '/robots.txt', '/sitemap.xml'].includes(url.pathname);
    if (!isPublic && !sessions.has(getCookie(req, 'session'))) {
      res.writeHead(302, { Location: '/login' });
      return res.end();
    }

    switch (url.pathname) {
      case '/':
        return html(res, 200, views.homePage(sessions.get(getCookie(req, 'session'))));

      case '/robots.txt':
        res.writeHead(200, { 'Content-Type': 'text/plain' });
        return res.end(fs.readFileSync(path.join(__dirname, 'robots.txt')));
      case '/sitemap.xml':
        res.writeHead(200, { 'Content-Type': 'application/xml' });
        return res.end(fs.readFileSync(path.join(__dirname, 'sitemap.xml')));
      case '/api/pegawai':
        return json(res, 200, await db.listPegawai());
      case '/api/produk':
        return json(res, 200, await db.listProduk());
      case '/health':
        return json(res, 200, { status: 'ok', waktu: new Date().toISOString() });
      default:
        return json(res, 404, { error: 'Tidak ditemukan' });
    }
  } catch (err) {
    console.error('Kesalahan server:', err);
    return json(res, 500, { error: 'Kesalahan server' });
  }
});

const PORT = process.env.PORT || 8080;
server.listen(PORT, '0.0.0.0', () => console.log(`Server berjalan di port ${PORT}`));
