import { Router } from 'express'
import {
    getProfile,
    updateProfile,
    getPendingUsers,
    approveUser,
    getAllUsers,
    getAllResidents,
    createSecurityAccount
} from '../controllers/userController'
import { authenticateToken, requireEstateAdmin } from '../middleware/auth'

const router = Router()

// ... (imports)

/**
 * @swagger
 * /users/profile:
 *   get:
 *     summary: Get current user profile
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User profile
 */
router.get('/profile', authenticateToken, getProfile)
router.put('/profile', authenticateToken, updateProfile)

// Estate Admin Routes

/**
 * @swagger
 * /users/residents:
 *   get:
 *     summary: Get all residents in the estate (Admin only)
 *     tags: [Estate Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of residents
 */
router.get('/residents', authenticateToken, getAllResidents)

router.get('/pending', authenticateToken, getPendingUsers)
router.post('/:id/approve', authenticateToken, approveUser)
router.post('/security', authenticateToken, requireEstateAdmin, createSecurityAccount)

// Super Admin Routes
router.get('/', authenticateToken, getAllUsers)

export default router
