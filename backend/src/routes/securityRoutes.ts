import { Router } from 'express'
import { getLogs, addManualLog, getAnnouncements, createAnnouncement } from '../controllers/securityController'
import { authenticateToken } from '../middleware/auth'

const router = Router()
router.use(authenticateToken)

router.get('/logs', getLogs)
router.post('/logs', addManualLog)
router.get('/announcements', getAnnouncements)
router.post('/announcements', createAnnouncement)

export default router
