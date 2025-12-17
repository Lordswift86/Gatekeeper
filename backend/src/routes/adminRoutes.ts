import { Router } from 'express'
import { authenticateToken } from '../middleware/auth'
import { getPlatformStats, getSystemLogs } from '../controllers/adminController'

const router = Router()

// All admin routes require authentication
router.use(authenticateToken)

// Platform stats for Super Admin dashboard
router.get('/stats', getPlatformStats)

// System logs
router.get('/system-logs', getSystemLogs)

export default router
