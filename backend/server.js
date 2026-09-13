const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const app = express();

app.use(express.json());

const db = new sqlite3.Database('./database.sqlite', (err) => {
  if (err) console.error(err.message);
});

db.serialize(() => {
  db.run(`CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE,
    password TEXT,
    tier TEXT,
    duration_minutes INTEGER,
    expires_at INTEGER,
    hwid TEXT,
    is_active INTEGER DEFAULT 1
  )`);

  db.run(`CREATE TABLE IF NOT EXISTS servers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    protocol TEXT,
    host TEXT,
    port INTEGER,
    sni TEXT,
    is_active INTEGER DEFAULT 1
  )`);
});

// Admin Endpoint: তৈরি করুন অ্যাকাউন্ট (যেমন: 60 mins বা 43200 mins = 30 days)
app.post('/api/admin/create-user', (req, res) => {
  const { username, password, tier, duration_minutes } = req.body;
  const now = Date.now();
  const expires_at = now + (duration_minutes * 60 * 1000);

  db.run(
    `INSERT INTO users (username, password, tier, duration_minutes, expires_at) VALUES (?, ?, ?, ?, ?)`,
    [username, password, tier || 'Premium', duration_minutes, expires_at],
    function (err) {
      if (err) return res.status(400).json({ error: 'User already exists' });
      res.json({ message: 'User created successfully', username, expires_at, tier });
    }
  );
});

// Client Login & Device HWID Binding Endpoint
app.post('/api/auth', (req, res) => {
  const { username, password, hwid } = req.body;

  db.get(`SELECT * FROM users WHERE username = ? AND password = ?`, [username, password], (err, user) => {
    if (err || !user) return res.status(401).json({ error: 'Invalid credentials' });
    if (!user.is_active) return res.status(403).json({ error: 'Account suspended' });

    const now = Date.now();
    if (now > user.expires_at) {
      return res.status(403).json({ error: 'Account expired', expires_at: user.expires_at });
    }

    if (!user.hwid) {
      db.run(`UPDATE users SET hwid = ? WHERE id = ?`, [hwid, user.id]);
    } else if (user.hwid !== hwid) {
      return res.status(403).json({ error: 'Device bound to another HWID (Max 1 Device Allowed)' });
    }

    db.all(`SELECT * FROM servers WHERE is_active = 1`, [], (err, servers) => {
      res.json({
        username: user.username,
        tier: user.tier,
        expires_at: user.expires_at,
        servers: servers || []
      });
    });
  });
});

app.listen(3000, () => console.log('License Engine running on port 3000'));
