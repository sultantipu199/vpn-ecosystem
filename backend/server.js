const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

const db = new sqlite3.Database('./database.sqlite', (err) => {
  if (err) console.error('Database connection error:', err.message);
  else console.log('Connected to SQLite database.');
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

  // Auto-seed default demo account (1 Year validity)
  const defaultExpiry = Date.now() + (365 * 24 * 60 * 60 * 1000);
  db.run(
    `INSERT OR IGNORE INTO users (username, password, tier, duration_minutes, expires_at, is_active) 
     VALUES ('232248', '08859', 'VIP Enterprise', 525600, ?, 1)`,
    [defaultExpiry]
  );

  // Auto-seed default gateway server
  db.get(`SELECT COUNT(*) as count FROM servers`, [], (err, row) => {
    if (!err && row && row.count === 0) {
      db.run(`INSERT INTO servers (name, protocol, host, port, sni, is_active) 
              VALUES ('US Cloud Gateway (Low Ping)', 'Shadowsocks / V2Ray', 'vpn-license-backend.onrender.com', 443, 'vpn-license-backend.onrender.com', 1)`);
    }
  });
});

// Admin Dashboard Web Page
app.get('/admin', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'admin.html'));
});

// Root route redirects to Admin Control Panel
app.get('/', (req, res) => {
  res.redirect('/admin');
});

// 1-Click Direct APK Downloads (Points to latest release automatically)
app.get('/download', (req, res) => {
  res.redirect('https://github.com/sultantipu199/vpn-ecosystem/releases/latest/download/app-arm64-v8a-release.apk');
});
app.get('/download/arm64', (req, res) => {
  res.redirect('https://github.com/sultantipu199/vpn-ecosystem/releases/latest/download/app-arm64-v8a-release.apk');
});
app.get('/download/armv7', (req, res) => {
  res.redirect('https://github.com/sultantipu199/vpn-ecosystem/releases/latest/download/app-armeabi-v7a-release.apk');
});
app.get('/download/x86_64', (req, res) => {
  res.redirect('https://github.com/sultantipu199/vpn-ecosystem/releases/latest/download/app-x86_64-release.apk');
});

// Health check & Server status
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', time: new Date().toISOString() });
});

// --- ADMIN API ENDPOINTS ---

// 1. Get all users
app.get('/api/admin/users', (req, res) => {
  db.all(`SELECT id, username, password, tier, duration_minutes, expires_at, hwid, is_active FROM users ORDER BY id DESC`, [], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows || []);
  });
});

// 2. Create new user
app.post('/api/admin/create-user', (req, res) => {
  const { username, password, tier, duration_minutes } = req.body;

  if (!username || !password || !duration_minutes) {
    return res.status(400).json({ error: 'Username, password, and duration are required' });
  }

  const now = Date.now();
  const expires_at = now + (Number(duration_minutes) * 60 * 1000);

  db.run(
    `INSERT INTO users (username, password, tier, duration_minutes, expires_at) VALUES (?, ?, ?, ?, ?)`,
    [username.trim(), password.trim(), tier || 'Premium', Number(duration_minutes), expires_at],
    function (err) {
      if (err) return res.status(400).json({ error: 'Username already exists' });
      res.json({
        message: 'User created successfully',
        id: this.lastID,
        username: username.trim(),
        expires_at,
        tier: tier || 'Premium'
      });
    }
  );
});

// 3. Reset HWID device lock
app.post('/api/admin/reset-hwid', (req, res) => {
  const { id } = req.body;
  if (!id) return res.status(400).json({ error: 'User ID is required' });

  db.run(`UPDATE users SET hwid = NULL WHERE id = ?`, [id], function (err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: 'Device lock (HWID) reset successfully' });
  });
});

// 4. Toggle Active / Suspended status
app.post('/api/admin/toggle-status', (req, res) => {
  const { id, is_active } = req.body;
  if (id === undefined || is_active === undefined) {
    return res.status(400).json({ error: 'User ID and status are required' });
  }

  db.run(`UPDATE users SET is_active = ? WHERE id = ?`, [is_active ? 1 : 0, id], function (err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: `User ${is_active ? 'activated' : 'suspended'} successfully` });
  });
});

// 5. Delete user
app.post('/api/admin/delete-user', (req, res) => {
  const { id } = req.body;
  if (!id) return res.status(400).json({ error: 'User ID is required' });

  db.run(`DELETE FROM users WHERE id = ?`, [id], function (err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: 'User deleted successfully' });
  });
});

// --- CLIENT AUTH ENDPOINT ---
app.post('/api/auth', (req, res) => {
  const { username, password, hwid } = req.body;

  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password required' });
  }

  db.get(`SELECT * FROM users WHERE username = ? AND password = ?`, [username.trim(), password.trim()], (err, user) => {
    if (err || !user) return res.status(401).json({ error: 'Invalid credentials' });
    if (!user.is_active) return res.status(403).json({ error: 'Account suspended' });

    const now = Date.now();
    if (now > user.expires_at) {
      return res.status(403).json({ error: 'Account expired', expires_at: user.expires_at });
    }

    if (!user.hwid) {
      db.run(`UPDATE users SET hwid = ? WHERE id = ?`, [hwid, user.id]);
    } else if (hwid && user.hwid !== hwid) {
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

app.listen(PORT, '0.0.0.0', () => {
  console.log(`License Engine running on port ${PORT}`);
});
