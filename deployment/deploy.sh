#!/bin/bash
# GateKeeper Deployment Script for Hostinger VPS
# Usage: ./deploy.sh [--backend] [--frontend] [--full]

set -e

# Configuration
DEPLOY_USER="root"
DEPLOY_HOST="31.97.183.43"
DEPLOY_PATH="/var/www/gatekeeper"
REPO_URL="https://github.com/Lordswift86/Gatekeeper.git"

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

    # Get script directory to find project root
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    PROJECT_ROOT="$SCRIPT_DIR/.."
    BACKEND_DIR="$PROJECT_ROOT/backend"

    # Sync backend files to VPS
    log "Syncing backend files to VPS..."
    rsync -avz --delete --exclude 'node_modules' --exclude 'dist' --exclude '.env' "$BACKEND_DIR/" ${DEPLOY_USER}@${DEPLOY_HOST}:/var/www/gatekeeper/backend/

    ssh ${DEPLOY_USER}@${DEPLOY_HOST} << 'ENDSSH'
        cd /var/www/gatekeeper/backend
        
        # Install regular dependencies (for build)
        npm ci
        
        # PATCH: Switch Prisma to PostgreSQL (since we can't push to repo)
        sed -i 's/provider = "sqlite"/provider = "postgresql"/g' prisma/schema.prisma
        
        # PATCH: Fix PM2 script path
        sed -i 's/server.js/app.js/g' ecosystem.config.js
        
        # Build TypeScript
        npm run build
        
        # Generate Prisma Client (with new provider)
        npx prisma generate
        
        # Run database migrations
        npx prisma migrate deploy
        
        # Restart PM2
        export PATH=$PATH:/usr/bin:/usr/local/bin:/usr/sbin:/usr/local/sbin
        pm2 reload ecosystem.config.js --env production || pm2 start ecosystem.config.js --env production
        
        echo "Backend deployed successfully!"
ENDSSH
}

# Deploy Frontend
deploy_frontend() {
    log "Deploying Frontend..."
    
    # Get script directory to find project root
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    PROJECT_ROOT="$SCRIPT_DIR/.."
    FRONTEND_DIR="$PROJECT_ROOT/web_dashboard"
    
    # Build locally
    log "Building frontend in $FRONTEND_DIR..."
    cd "$FRONTEND_DIR"
    npm install # Ensure deps are installed locally
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
        
        # Clone repo
        rm -rf /var/www/gatekeeper
        git clone https://github.com/Lordswift86/Gatekeeper.git /var/www/gatekeeper
        cd /var/www/gatekeeper
        
        # Install PostgreSQL (optional - can use external DB)
        # apt install -y postgresql postgresql-contrib
        
        # Setup PM2 startup
        export PATH=$PATH:/usr/bin:/usr/local/bin:/usr/sbin:/usr/local/sbin
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
