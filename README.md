# Enterprise VPN Ecosystem

### 📱 1-Click Direct Download Links (Android APK)
Anyone can download the compiled production APK directly without logging into GitHub:

| Architecture | Device Type | Direct 1-Click Download | File Size |
|---|---|---|---|
| **ARM64 (v8a)** *(Recommended)* | Modern Android Phones (95%+) | **[⬇️ Download APK (v1.0.1 - WiFi Fixed)](https://github.com/sultantipu199/vpn-ecosystem/releases/latest/download/app-arm64-v8a-release.apk)** | ~7.9 MB |
| **ARMeabi (v7a)** | Older 32-bit Android Phones | **[⬇️ Download APK (v1.0.1 - WiFi Fixed)](https://github.com/sultantipu199/vpn-ecosystem/releases/latest/download/app-armeabi-v7a-release.apk)** | ~7.4 MB |
| **x86_64** | Emulators / ChromeOS | **[⬇️ Download APK (v1.0.1 - WiFi Fixed)](https://github.com/sultantipu199/vpn-ecosystem/releases/latest/download/app-x86_64-release.apk)** | ~8.0 MB |

> 🌐 **Live Cloud Backend & Admin Panel**: [https://vpn-license-backend.onrender.com/admin](https://vpn-license-backend.onrender.com/admin)  
> 🔗 **Direct APK Download Route**: [https://vpn-license-backend.onrender.com/download](https://vpn-license-backend.onrender.com/download)  
> 📦 **Release Notes & Changelog**: [GitHub Releases (v1.0.1)](https://github.com/sultantipu199/vpn-ecosystem/releases/tag/v1.0.1)

---

An end-to-end Enterprise VPN platform featuring:
- **GitLab CI/CD & GitHub Actions**: Automated Docker-based APK compilation (`app-arm64-v8a-release.apk` & `app-armeabi-v7a-release.apk`) on push to `main`.
- **Android Native VpnService (Kotlin)**: Foreground service notification with action controls, TUN interface creation (`10.0.0.2/24`, DNS `1.1.1.1`, MTU 1500), and Flutter MethodChannel bridge (`com.tunnel.vpn/core`).
- **Flutter Client UI**: Dark theme account dashboard card with real-time expiration countdown ticker (`days/hours/mins/secs`), kill-switch modal trigger on expiry, and connect/disconnect control.
- **Node.js + SQLite Licensing Backend**: Admin user creation endpoint, client authentication with single-device HWID binding lock, expiration enforcement, and active server list distribution.

---

## 📁 Project Structure

```
vp/
├── setup_project.sh                                    # Root automation generator script
└── vpn_ecosystem/
    ├── .gitlab-ci.yml                                  # GitLab CI/CD configuration
    ├── pubspec.yaml                                    # Flutter project dependencies
    ├── README.md                                       # Project documentation
    ├── backend/
    │   ├── package.json                                # Node.js backend package
    │   └── server.js                                   # Express + SQLite licensing engine
    ├── android/
    │   └── app/src/main/
    │       ├── AndroidManifest.xml                     # Permissions & VpnService declaration
    │       ├── kotlin/com/tunnel/vpn/
    │       │   ├── MainActivity.kt                     # Flutter MethodChannel platform bridge
    │       │   └── TunnelVpnService.kt                 # Android native VpnService implementation
    │       └── res/values/
    │           └── styles.xml                          # LaunchTheme styles configuration
    └── lib/
        ├── main.dart                                   # Flutter main entry point & VpnHomeScreen
        ├── models/
        │   └── user_model.dart                         # UserModel and ServerInfo data classes
        ├── services/
        │   └── api_service.dart                        # Backend HTTP API client
        └── screens/
            └── account_card.dart                       # Dynamic account status & countdown card
```

---

## 🚀 Quick Start Guide

### 1. Running the Licensing Backend Locally

Ensure Node.js is installed on your host machine, then run:

```bash
cd vpn_ecosystem/backend
npm install
npm start
```

The licensing server starts on port `3000`:
- **Database**: SQLite (`database.sqlite` auto-created with `users` and `servers` tables)
- **Create Admin/User**: `POST http://localhost:3000/api/admin/create-user`
  ```json
  {
    "username": "client01",
    "password": "secretpassword",
    "tier": "Premium",
    "duration_minutes": 43200
  }
  ```
- **Client Auth & HWID Lock**: `POST http://localhost:3000/api/auth`
  ```json
  {
    "username": "client01",
    "password": "secretpassword",
    "hwid": "device-uuid-12345"
  }
  ```

---

### 2. Pushing to GitLab for Automated APK Build

To push the project to your GitLab repository and trigger the CI/CD pipeline:

```bash
cd vpn_ecosystem
git init
git remote add origin <YOUR_GITLAB_REPO_URL>
git add .
git commit -m "feat: complete vpn ecosystem"
git branch -M main
git push -u origin main
```

Once pushed:
1. Open your GitLab repository.
2. Go to **Build > Pipelines**.
3. View the pipeline status. Upon completion, download the compiled APK artifacts:
   - `app-arm64-v8a-release.apk`
   - `app-armeabi-v7a-release.apk`
