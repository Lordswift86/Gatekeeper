#!/bin/bash
# GateKeeper Deployment Script for Hostinger VPS
# Usage: ./deploy.sh [--backend] [--frontend] [--full]

set -e

# Configuration
DEPLOY_USER="root"
DEPLOY_HOST="your-vps-ip"
DEPLOY_PATH="/var/www/gatekeeper"
REPO_URL="git@github.com:yourusername/gatekeeper.git"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[DEPLOY]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check SSH connection
check_connection() {
    log "Checking SSH connection..."
    ssh -q ${DEPLOY_USER}@${DEPLOY_HOST} exit || error "Cannot connect to VPS"
}

# Deploy Backend
deploy_backend() {
    log "Deploying Backend..."
    
    ssh ${DEPLOY_USER}@${DEPLOY_HOST} << 'ENDSSH'
        cd /var/www/gatekeeper/backend
        
        # Pull latest code
        git fetch origin
        git reset --hard origin/main
        
        # Install dependencies
        npm ci --production
        
        # Build TypeScript
        npm run build
        
        # Run database migrations
        npx prisma migrate deploy
        
        # Restart PM2
        pm2 reload ecosystem.config.js --env production
        
        echo "Backend deployed successfully!"
ENDSSH
}

# Deploy Frontend
deploy_frontend() {
    log "Deploying Frontend..."
    
    # Build locally
    log "Building frontend..."
    npm run build
    
    # Upload to VPS
    log "Uploading to VPS..."
    rsync -avz --delete dist/ ${DEPLOY_USER}@${DEPLOY_HOST}:${DEPLOY_PATH}/frontend/dist/
    
    log "Frontend deployed successfully!"
}

# Full deploy
deploy_full() {
    deploy_backend
    deploy_frontend
    
    ssh ${DEPLOY_USER}@${DEPLOY_HOST} << 'ENDSSH'
        # Reload Nginx
        sudo nginx -t && sudo systemctl reload nginx
        echo "Full deployment complete!"
ENDSSH
}

# First-time setup
setup_vps() {
    log "Setting up VPS..."
    
    ssh ${DEPLOY_USER}@${DEPLOY_HOST} << 'ENDSSH'
        # Update system
        apt update && apt upgrade -y
        
        # Install Node.js 20
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt install -y nodejs
        
        # Install PM2
        npm install -g pm2
        
        # Install Nginx
        apt install -y nginx
        
        # Install Certbot for SSL
        apt install -y certbot python3-certbot-nginx
        
        # Create directories
        mkdir -p /var/www/gatekeeper/{backend,frontend/dist}
        mkdir -p /var/log/pm2
        
        # Clone repo
        cd /var/www/gatekeeper
        git clone ${REPO_URL} .
        
        # Install PostgreSQL (optional - can use external DB)
        # apt install -y postgresql postgresql-contrib
        
        # Setup PM2 startup
        pm2 startup
        
        echo "VPS setup complete!"
ENDSSH
}

# Parse arguments
case "$1" in
    --backend)
        check_connection
        deploy_backend
        ;;
    --frontend)
        check_connection
        deploy_frontend
        ;;
    --full)
        check_connection
        deploy_full
        ;;
    --setup)
        check_connection
        setup_vps
        ;;
    *)
        echo "GateKeeper Deployment Script"
        echo ""
        echo "Usage: ./deploy.sh [option]"
        echo ""
        echo "Options:"
        echo "  --backend   Deploy backend only"
        echo "  --frontend  Deploy frontend only"
        echo "  --full      Deploy both + reload nginx"
        echo "  --setup     First-time VPS setup"
        ;;
esac
