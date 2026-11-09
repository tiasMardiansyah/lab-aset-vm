const esc = (s) =>
  String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

const loginPage = (error = '') => `<!DOCTYPE html>
<html lang="id"><head><meta charset="utf-8"><title>Login - PT Kucing Tiga</title></head>
  <body>
    <h1>Portal Internal PT Kucing Tiga (FIKTIF)</h1>
    ${error ? `<p style="color:#b00">${error}</p>` : ''}
    <form method="post" action="/login">
      <p><label>Username <input name="username" required autofocus></label></p>
      <p><label>Password <input name="password" type="password" required></label></p>
      <p><button>Masuk</button></p>
    </form>
  </body>
</html>`;

const homePage = (user) => `<!DOCTYPE html>
<html lang="id"><head><meta charset="utf-8"><title>PT Kucing Tiga</title></head>
  <body>
    <h1>Portal Internal PT Kucing Tiga (FIKTIF)</h1>
    <p>Masuk sebagai <strong>${esc(user)}</strong> | <a href="/logout">Logout</a></p>
    <ul>
        <li><a href="/api/pegawai">Data Pegawai</a></li>
        <li><a href="/api/produk">Data Produk</a></li>
        <li><a href="/health">Health Check</a></li>
    </ul>
  </body>
</html>`;

module.exports = { loginPage, homePage };
