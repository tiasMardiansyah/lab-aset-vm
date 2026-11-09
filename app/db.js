const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: process.env.DB_HOST || '127.0.0.1',
  user: process.env.DB_USER || 'aset',
  password: process.env.DB_PASS || 'aset',
  database: process.env.DB_NAME || 'aset_lab',
  connectionLimit: 5,
});

const findUser = async (username, passwordHash) => {
  const [rows] = await pool.query(
    'SELECT id, username FROM users WHERE username = ? AND password = ?',
    [username, passwordHash]
  );
  return rows[0] || null;
};

const listPegawai = async () => {
  const [rows] = await pool.query('SELECT id, nama, role, email FROM pegawai ORDER BY id');
  return rows;
};

const listProduk = async () => {
  const [rows] = await pool.query('SELECT kode, nama, stok, harga FROM produk ORDER BY kode');
  return rows;
};

module.exports = { findUser, listPegawai, listProduk };
