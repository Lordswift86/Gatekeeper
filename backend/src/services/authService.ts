import prisma from '../config/db'
import bcrypt from 'bcryptjs'
import jwt from 'jsonwebtoken'



export const AuthService = {
    async login(email: string) {
        const user = await prisma.user.findUnique({ where: { email } })
        if (!user) return null

        // Generate tokens
        const accessToken = this.generateAccessToken(user)
        const refreshToken = await this.generateRefreshToken(user.id)

        const { password: _, ...userWithoutPassword } = user
        return { user: userWithoutPassword, accessToken, refreshToken }
    },

    // Unified login handler (Email or Phone)
    async loginWithPassword(identifier: string, passwordPlain: string) {
        const isEmail = identifier.includes('@')
        let user

        if (isEmail) {
            user = await prisma.user.findUnique({ where: { email: identifier } })
        } else {
            const { OTPService } = require('./smsService')
            const formattedPhone = OTPService.formatPhone(identifier)
            user = await prisma.user.findUnique({ where: { phone: formattedPhone } })
        }

        if (!user) throw new Error('Invalid credentials')

        if (!user.phoneVerified && !isEmail) {
            throw new Error('Account verification pending. Please complete registration.')
        }

        const isValid = await bcrypt.compare(passwordPlain, user.password)
        if (!isValid) throw new Error('Invalid credentials')

        // Generate tokens
        const accessToken = this.generateAccessToken(user)
        const refreshToken = await this.generateRefreshToken(user.id)

        const { password: _, ...userWithoutPassword } = user
        return { user: userWithoutPassword, accessToken, refreshToken }
    },

    generateAccessToken(user: any) {
        return jwt.sign(
            { userId: user.id, role: user.role, estateId: user.estateId },
            process.env.JWT_SECRET || 'secret',
            { expiresIn: '15m' } // Short-lived access token
        )
    },

    async generateRefreshToken(userId: string) {
        // Generate random token
        const token = require('crypto').randomBytes(40).toString('hex')
        const expiresAt = new Date()
        expiresAt.setDate(expiresAt.getDate() + 30) // 30 days expiry

        const refreshToken = await prisma.refreshToken.create({
            data: {
                token,
                userId,
                expiresAt
            }
        })

        return refreshToken.token
    },

    async refreshAccessToken(token: string) {
        const refreshToken = await prisma.refreshToken.findUnique({
            where: { token },
            include: { user: true }
        })

        if (!refreshToken || refreshToken.revoked || refreshToken.expiresAt < new Date()) {
            throw new Error('Invalid or expired refresh token')
        }

        // Generate new access token
        const accessToken = this.generateAccessToken(refreshToken.user)

        // Optional: Rotate refresh token (security best practice)
        // For now, we keep the same refresh token until expiry to avoid race conditions with multiple requests

        return { accessToken }
    },

    async logout(token: string) {
        await prisma.refreshToken.update({
            where: { token },
            data: { revoked: true }
        })
    },

    async register(data: {
        phone: string;
        name: string;
        password: string;
        role: string;
        estateCode: string;
        unitNumber?: string;
        email?: string;
    }) {
        const { phone, name, password, role, estateCode, unitNumber, email } = data

        // Security accounts can only be created by Estate Admin
        if (role === 'SECURITY') {
            throw new Error('Security accounts must be created by Estate Admin')
        }

        // Format and validate phone
        const { OTPService } = require('./smsService')
        const formattedPhone = OTPService.formatPhone(phone)

        if (!OTPService.validatePhoneFormat(formattedPhone)) {
            throw new Error('Invalid phone number format')
        }

        // Check if phone already exists
        const existingUser = await prisma.user.findUnique({ where: { phone: formattedPhone } })
        if (existingUser) throw new Error('Phone number already registered')

        // Validate estate code
        const estate = await prisma.estate.findUnique({ where: { code: estateCode } })
        if (!estate) throw new Error('Invalid Estate Code')

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 12)

        // Create user (phoneVerified will be set after OTP verification)
        const user = await prisma.user.create({
            data: {
                phone: formattedPhone,
                phoneVerified: false, // Must verify OTP
                email,
                name,
                password: hashedPassword,
                role,
                estateId: estate.id,
                unitNumber,
                isApproved: false
            }
        })

        const { password: _, ...userWithoutPassword } = user
        return {
            user: userWithoutPassword,
            message: 'Registration successful. Please verify your phone number with OTP.'
        }
    },

    async registerEstateAdmin(data: {
        user: { name: string; phone: string; password: string; email?: string; referralCode?: string };
        estate: { name: string; address?: string; description?: string };
    }) {
        const { user: userData, estate: estateData } = data

        // Format and validate phone
        const { OTPService } = require('./smsService')
        const formattedPhone = OTPService.formatPhone(userData.phone)

        if (!OTPService.validatePhoneFormat(formattedPhone)) {
            throw new Error('Invalid phone number format')
        }

        // Check if phone already exists
        const existingUser = await prisma.user.findUnique({ where: { phone: formattedPhone } })
        if (existingUser) throw new Error('Phone number already registered')

        // Generate unique estate code from name (e.g., "Sunset Gardens" -> "SUNSET")
        const generateCode = (name: string): string => {
            return name
                .split(' ')
                .map(word => word[0]?.toUpperCase())
                .join('')
                .slice(0, 6) + Math.floor(Math.random() * 100)
        }

        let estateCode = generateCode(estateData.name)

        // Ensure code is unique
        let codeExists = await prisma.estate.findUnique({ where: { code: estateCode } })
        while (codeExists) {
            estateCode = generateCode(estateData.name) + Math.floor(Math.random() * 1000)
            codeExists = await prisma.estate.findUnique({ where: { code: estateCode } })
        }

        // Create estate with PENDING status
        const estate = await prisma.estate.create({
            data: {
                name: estateData.name,
                code: estateCode,
                address: estateData.address,
                description: estateData.description,
                status: 'PENDING' // Requires Super Admin approval
            }
        })

        // Hash password
        const hashedPassword = await bcrypt.hash(userData.password, 12)

        // Create estate admin user (not approved yet)
        const user = await prisma.user.create({
            data: {
                phone: formattedPhone,
                phoneVerified: false, // Must verify OTP
                email: userData.email,
                name: userData.name,
                password: hashedPassword,
                role: 'ESTATE_ADMIN',
                estateId: estate.id,
                isApproved: false // Requires Super Admin approval
            }
        })

        // Link to referrer if referral code provided
        if (userData.referralCode) {
            try {
                const { ReferralService } = require('./referralService')
                await ReferralService.linkReferral(user.id, userData.referralCode)
            } catch (error) {
                // Don't fail registration if referral linking fails
                console.warn('Referral linking failed:', error)
            }
        }

        const { password: _, ...userWithoutPassword } = user

        return {
            message: 'Registration submitted. Awaiting Super Admin approval. Please verify your phone number with OTP.',
            estateCode: estate.code,
            status: 'PENDING',
            user: userWithoutPassword
        }
    },

    async resetPassword(phone: string, newPassword: string) {
        // Format phone number
        const { OTPService } = require('./smsService')
        const formattedPhone = OTPService.formatPhone(phone)

        // Find user by phone
        const user = await prisma.user.findUnique({ where: { phone: formattedPhone } })
        if (!user) {
            throw new Error('User not found')
        }

        // Hash new password
        const hashedPassword = await bcrypt.hash(newPassword, 12)

        // Update password
        await prisma.user.update({
            where: { id: user.id },
            data: { password: hashedPassword }
        })
    }
}
