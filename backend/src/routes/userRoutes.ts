import { Router } from 'express'
import { getProfile, updateProfile, getPendingUsers, approveUser, getAllUsers, getAllResidents } from '../controllers/userController'
import { authenticateToken } from '../middleware/auth'

const router = Router()

router.get('/profile', authenticateToken, getProfile)
router.put('/profile', authenticateToken, updateProfile)
router.get('/pending', authenticateToken, getPendingUsers)
router.post('/:id/approve', authenticateToken, approveUser)
router.get('/all', authenticateToken, getAllUsers)
router.get('/residents', authenticateToken, getAllResidents)

export default router
