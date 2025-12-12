import express from 'express'
import cors from 'cors'
import helmet from 'helmet'
import morgan from 'morgan'
import dotenv from 'dotenv'

dotenv.config()

const app = express()
const PORT = process.env.PORT || 3000

// Middleware
app.use(cors())
app.use(helmet())
app.use(morgan('dev'))
app.use(express.json())

// Health Check
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date() })
})

import authRoutes from './routes/authRoutes'
import estateRoutes from './routes/estateRoutes'
import passRoutes from './routes/passRoutes'
import userRoutes from './routes/userRoutes'
import billRoutes from './routes/billRoutes'
import securityRoutes from './routes/securityRoutes'
import globalAdRoutes from './routes/globalAdRoutes'

// Routes
app.use('/api/auth', authRoutes)
app.use('/api/estates', estateRoutes)
app.use('/api/passes', passRoutes)
app.use('/api/users', userRoutes)
app.use('/api/bills', billRoutes)
app.use('/api/security', securityRoutes)
app.use('/api/admin/global-ads', globalAdRoutes)
// ...

import { createServer } from 'http'
import { setupSocket } from './socket'

if (require.main === module) {
    const httpServer = createServer(app)
    setupSocket(httpServer)

    httpServer.listen(PORT, () => {
        console.log(`🚀 Server running on port ${PORT}`)
        console.log(`📡 WebSocket server ready`)
    })
}

export default app
