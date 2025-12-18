import { Router } from 'express'
import { generatePass, getMyPasses, getEstatePasses, validatePass, entryPass, exitPass, cancelPass } from '../controllers/passController'
import { authenticateToken } from '../middleware/auth'

const router = Router()

router.use(authenticateToken) // All pass routes require auth

// ... (imports remain)
// ... (router setup remains)

/**
 * @swagger
 * /passes/generate:
 *   post:
 *     summary: Generate a new guest pass
 *     tags: [Passes]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - guestName
 *               - type
 *             properties:
 *               guestName:
 *                 type: string
 *               type:
 *                 type: string
 *                 enum: [ONE_TIME, RECURRING, DELIVERY]
 *               exitInstruction:
 *                 type: string
 *               deliveryCompany:
 *                 type: string
 *     responses:
 *       201:
 *         description: Pass generated successfully
 */
router.post('/generate', generatePass)

/**
 * @swagger
 * /passes/my-passes:
 *   get:
 *     summary: Get all passes created by the user
 *     tags: [Passes]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of passes
 */
router.get('/my-passes', getMyPasses)

/**
 * @swagger
 * /passes/estate:
 *   get:
 *     summary: Get all passes in the estate (Admin/Security only)
 *     tags: [Passes]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of all estate passes
 */
router.get('/estate', getEstatePasses)

// Security Actions

/**
 * @swagger
 * /passes/validate:
 *   post:
 *     summary: Validate a pass code (Security only)
 *     tags: [Passes - Security]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [code]
 *             properties:
 *               code:
 *                 type: string
 *     responses:
 *       200:
 *         description: Pass is valid
 *       400:
 *         description: Invalid or expired pass
 */
router.post('/validate', validatePass)

router.post('/:id/entry', entryPass)
router.post('/:id/exit', exitPass)

/**
 * @swagger
 * /passes/{id}:
 *   delete:
 *     summary: Cancel a pass
 *     tags: [Passes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Pass cancelled
 */
router.delete('/:id', cancelPass)

export default router
