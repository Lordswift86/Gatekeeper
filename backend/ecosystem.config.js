// PM2 Ecosystem Configuration for Hostinger VPS
// Run: pm2 start ecosystem.config.js --env production

module.exports = {
    apps: [
        {
            name: 'gatekeeper-api',
            script: './dist/server.js',
            cwd: '/var/www/gatekeeper/backend',
            instances: 'max',
            exec_mode: 'cluster',
            env: {
                NODE_ENV: 'development',
                PORT: 5000
            },
            env_production: {
                NODE_ENV: 'production',
                PORT: 5000
            },
            // Logging
            log_file: '/var/log/pm2/gatekeeper-api.log',
            out_file: '/var/log/pm2/gatekeeper-api-out.log',
            error_file: '/var/log/pm2/gatekeeper-api-error.log',
            log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
            // Auto-restart on crash
            autorestart: true,
            max_restarts: 10,
            restart_delay: 1000,
            // Watch for file changes (disabled in production)
            watch: false,
            // Memory limit
            max_memory_restart: '500M'
        }
    ]
};
