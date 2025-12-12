import { Router } from 'express'
import { generatePass, getMyPasses, validatePass, entryPass, exitPass } from '../controllers/passController'
import { authenticateToken } from '../middleware/auth'

const router = Router()

router.use(authenticateToken) // All pass routes require auth

router.post('/generate', generatePass)
router.get('/my-passes', getMyPasses)

// Security Actions
router.post('/validate', validatePass)
router.post('/:id/entry', entryPass)
router.post('/:id/exit', exitPass)

export default router
