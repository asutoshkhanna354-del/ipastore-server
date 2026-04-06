# THE IPA STORE — Self-Hosting Guide

## Requirements
- Node.js 18 or newer
- A server with HTTPS (iOS requires HTTPS for OTA install)
- A domain with a valid SSL certificate

---

## Folder Structure
```
ipastore/
  dist/          ← compiled server (Node.js ESM)
  public/        ← frontend website (static HTML/CSS/JS)
  ipa/           ← app.ipa (the signed IPA)
  certs/         ← cert.p12 + profile.mobileprovision (for re-signing)
  bin/           ← zsign binary (Linux x64)
  keys.json      ← user install keys
  package.json
  start.sh
```

---

## Option 1: Plain VPS (Ubuntu/Debian)

```bash
# 1. Install Node.js 18+
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# 2. Copy this folder to your server
# e.g.: scp -r ipastore/ user@yourserver.com:/home/user/

# 3. Set up HTTPS (use nginx + certbot)
sudo apt install nginx certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com

# 4. Configure nginx to proxy to Node
# Add to /etc/nginx/sites-available/default inside server {}:
#
#   location / {
#       proxy_pass http://127.0.0.1:3000;
#       proxy_set_header Host $host;
#       proxy_set_header X-Forwarded-Proto $scheme;
#       proxy_set_header X-Forwarded-Host $host;
#   }
#
sudo nginx -s reload

# 5. Start the server
cd /home/user/ipastore
chmod +x start.sh
PORT=3000 ./start.sh

# 6. Keep it running (optional — use pm2)
npm install -g pm2
pm2 start "PORT=3000 node --enable-source-maps ./dist/index.mjs" --name ipastore
pm2 save
pm2 startup
```

---

## Option 2: Railway (free tier available)

1. Go to https://railway.app → New Project → Deploy from GitHub
2. Push this folder to a GitHub repo
3. Set environment variable: `PORT=3000`
4. Railway auto-detects Node.js, runs `npm start`
5. Add a custom domain in Railway settings

---

## Option 3: Render (free tier available)

1. Go to https://render.com → New Web Service
2. Connect your GitHub repo containing this folder
3. Build command: (leave empty)
4. Start command: `node --enable-source-maps ./dist/index.mjs`
5. Environment variable: `PORT=10000` (Render uses 10000)

---

## Admin Keys (hardcoded, always work)
- `IPASTORE-ADMIN`
- `ADMIN-LIFETIME-KEY`

## Adding User Keys
Edit `keys.json` and add entries:
```json
{ "key": "YOUR-KEY-HERE", "used": false, "usedAt": null, "usedBy": null }
```
Restart the server after editing.

---

## Re-signing a New IPA

```bash
# Requires Linux (the zsign binary in bin/ is Linux x64)
./bin/zsign \
  -z 9 \
  -k certs/cert.p12 \
  -m certs/profile.mobileprovision \
  -o ipa/app.ipa \
  -p "AppleP12.com" \
  your-input.ipa
```

**Important:** The signing certificate expires. When it does, you need a new cert.p12 + profile.mobileprovision pair.

---

## How Install Works
1. User visits your site → enters key
2. Server validates key via POST /api/keys/validate
3. Browser opens itms-services:// pointing to GitHub manifest.plist
4. iOS fetches IPA from jsDelivr CDN (no bandwidth on your server)
5. iOS installs the app

The IPA itself is served from GitHub/jsDelivr CDN — your server only handles key validation (very light load).
