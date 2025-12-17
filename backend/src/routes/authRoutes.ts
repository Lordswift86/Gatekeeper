import { Router } from 'express'
import { login, register, registerEstateAdmin, refreshToken, logout, resetPassword } from '../controllers/authController'
import { sendOTP, verifyOTP } from '../controllers/otpController'
import { validate, schemas } from '../middleware/validate'

const router = Router()

/**
 * @swagger
 * /auth/login:
 *   post:
 *     summary: Login a user
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - password
 *             properties:
 *               identifier:
 *                 type: string
 *                 description: Email or Phone Number
 *               password:
 *                 type: string
 *     responses:
 *       200:
 *         description: Login successful
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 accessToken:
 *                   type: string
 *                 refreshToken:
 *                   type: string
 *                 user:
 *                   type: object
 */
router.post('/login', validate(schemas.login), login)
router.post('/refresh', refreshToken)
router.post('/logout', logout)

/**
 * @swagger
 * /auth/register:
 *   post:
 *     summary: Register a new user
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - email
 *               - password
 *               - role
 *               - estateCode
 *             properties:
 *               name:
 *                 type: string
 *               email:
 *                 type: string
 *               password:
 *                 type: string
 *               role:
 *                 type: string
 *                 enum: [RESIDENT, SECURITY]
 *               estateCode:
 *                 type: string
 *               unitNumber:
 *                 type: string
 *     responses:
 *       201:
 *         description: Registration successful
 */
router.post('/register', validate(schemas.register), register)
router.post('/register-estate-admin', validate(schemas.registerEstateAdmin), registerEstateAdmin)

// OTP routes
router.post('/send-otp', sendOTP) // Consider adding schema for this too
router.post('/verify-otp', verifyOTP)

// Password reset route
router.post('/reset-password', resetPassword)

export default router

