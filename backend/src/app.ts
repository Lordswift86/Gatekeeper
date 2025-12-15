import express from 'express'
import cors from 'cors'
import helmet from 'helmet'
import morgan from 'morgan'
import dotenv from 'dotenv'

dotenv.config()

const app = express()
const PORT = process.env.PORT || 3000
const isProduction = process.env.NODE_ENV === 'production'

// ============ Security Middleware ============

// CORS configuration
const corsOptions = {
    origin: isProduction
        ? (process.env.ALLOWED_ORIGINS || '').split(',').filter(Boolean)
        : '*', // Allow all in development
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}

app.use(cors(corsOptions))
app.use(helmet())

// Request logging - different format for production vs development
app.use(morgan(isProduction ? 'combined' : 'dev'))

// Body parsing with size limits
app.use(express.json({ limit: '10mb' }))
app.use(express.urlencoded({ extended: true, limit: '10mb' }))

// ============ Rate Limiting ============
import { apiLimiter, authLimiter } from './middleware/rateLimiter'

// Apply general rate limiter to all API routes
app.use('/api', apiLimiter)

// ============ Health Check ============
app.get('/api/health', (req, res) => {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV || 'development',
        version: process.env.npm_package_version || '1.0.0'
    })
})

// ============ Routes ============
import authRoutes from './routes/authRoutes'
import estateRoutes from './routes/estateRoutes'
import passRoutes from './routes/passRoutes'
import userRoutes from './routes/userRoutes'
import billRoutes from './routes/billRoutes'
import identityRoutes from './routes/identityRoutes';
import securityRoutes from './routes/securityRoutes'
import globalAdRoutes from './routes/globalAdRoutes'
import uploadRoutes from './routes/uploadRoutes';
import householdRoutes from './routes/householdRoutes';
import estateAdminRoutes from './routes/estateAdminRoutes';

// Swagger Imports
import swaggerUi from 'swagger-ui-express'
import swaggerSpec from './config/swagger'

// Apply stricter rate limit to auth routes
app.use('/api/auth', authLimiter, authRoutes)
app.use('/api/estates', estateRoutes)
app.use('/api/users', userRoutes);
app.use('/api/passes', passRoutes);
app.use('/api/bills', billRoutes);
app.use('/api/identity', identityRoutes);
app.use('/api/security', securityRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/household', householdRoutes);
app.use('/api/estate-admin', estateAdminRoutes);
app.use('/api/admin/global-ads', globalAdRoutes)

// Swagger Setup
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec))

// ============ Error Handling ============
import { errorHandler, notFoundHandler } from './middleware/errorHandler'

// 404 handler for unknown routes
app.use(notFoundHandler)

// Global error handler (must be last)
app.use(errorHandler)

// ============ Server Startup ============
import { createServer } from 'http'
import { setupSocket } from './socket'

if (require.main === module) {
    const httpServer = createServer(app)
    setupSocket(httpServer)

    httpServer.listen(PORT, () => {
        console.log(`🚀 Server running on port ${PORT}`)
        console.log(`📡 WebSocket server ready`)
        console.log(`🔒 Environment: ${process.env.NODE_ENV || 'development'}`)
        if (isProduction) {
            console.log(`🌐 CORS origins: ${corsOptions.origin}`)
        }
    })
}

export default app
