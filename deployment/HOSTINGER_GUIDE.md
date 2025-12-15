# GateKeeper Hostinger VPS Deployment Guide

## Prerequisites

1. **Hostinger VPS** with Ubuntu 22.04+
2. **Domain** pointed to VPS IP
3. **SSH access** to VPS

---

## Quick Start

### 1. First-Time VPS Setup

SSH into your VPS and run:

```bash
# Update system
apt update && apt upgrade -y

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Install PM2, Nginx, Certbot
npm install -g pm2
apt install -y nginx certbot python3-certbot-nginx

# Create directories
mkdir -p /var/www/gatekeeper/{backend,frontend/dist}
mkdir -p /var/log/pm2
```

### 2. Clone & Configure

```bash
cd /var/www/gatekeeper
git clone https://github.com/yourusername/gatekeeper.git .

# Backend setup
cd backend
cp .env.production .env
nano .env  # Edit with your values
npm ci --production
npm run build
npx prisma migrate deploy
```

### 3. Start API with PM2

```bash
pm2 start ecosystem.config.js --env production
pm2 save
pm2 startup
```

### 4. Configure Nginx

```bash
# Copy nginx config
cp /var/www/gatekeeper/deployment/nginx.conf /etc/nginx/sites-available/gatekeeper

# Edit domain name
nano /etc/nginx/sites-available/gatekeeper

# Enable site
ln -s /etc/nginx/sites-available/gatekeeper /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
```

### 5. Setup SSL

```bash
certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

### 6. Deploy Frontend

On your local machine:
```bash
# Build frontend
npm run build

# Upload to VPS
rsync -avz dist/ root@YOUR_VPS_IP:/var/www/gatekeeper/frontend/dist/
```

---

## Environment Variables

Edit `/var/www/gatekeeper/backend/.env`:

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | PostgreSQL connection string |
| `JWT_SECRET` | Random 64+ char string |
| `ALLOWED_ORIGINS` | Your domain (https://yourdomain.com) |
| `PAYSTACK_SECRET_KEY` | Paystack live key |

---

## Useful Commands

```bash
# View API logs
pm2 logs gatekeeper-api

# Restart API
pm2 restart gatekeeper-api

# Check status
pm2 status

# Nginx logs
tail -f /var/log/nginx/error.log
```

---

## Database Options

**Option A: External PostgreSQL** (Recommended)
- Use Hostinger's managed database
- Or services like Supabase, Neon, Railway

**Option B: Local PostgreSQL**
```bash
apt install -y postgresql postgresql-contrib
sudo -u postgres createdb gatekeeper_prod
sudo -u postgres psql -c "CREATE USER gatekeeper WITH PASSWORD 'yourpassword';"
sudo -u postgres psql -c "GRANT ALL ON DATABASE gatekeeper_prod TO gatekeeper;"
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| 502 Bad Gateway | Check PM2: `pm2 status` |
| SSL Error | Re-run certbot |
| API Not Responding | Check logs: `pm2 logs` |
| CORS Error | Update `ALLOWED_ORIGINS` |
