import { Router } from 'express'
import { getMyBills, getEstateBills, createBill, payBill, verifyPayment } from '../controllers/billController'
import { authenticateToken } from '../middleware/auth'

const router = Router()
router.use(authenticateToken)

// ...

/**
 * @swagger
 * /bills/my:
 *   get:
 *     summary: Get current user's bills
 *     tags: [Bills]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of bills
 */
router.get('/my', getMyBills)

router.get('/estate', getEstateBills)

/**
 * @swagger
 * /bills:
 *   post:
 *     summary: Create a new bill (Admin only)
 *     tags: [Bills]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [userId, amount, type, dueDate]
 *             properties:
 *               userId:
 *                 type: string
 *               amount:
 *                 type: number
 *               type:
 *                 type: string
 *               dueDate:
 *                 type: string
 *                 format: date-time
 *     responses:
 *       201:
 *         description: Bill created
 */
router.post('/', createBill)
router.post('/:id/pay', payBill)
router.post('/:id/verify-payment', verifyPayment)

export default router
