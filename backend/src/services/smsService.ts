import prisma from '../config/db'
import crypto from 'crypto'

// SMS Service with Africa's Talking integration
export const SMSService = {
    async sendSMS(phone: string, message: string): Promise<boolean> {
        const useRealSMS = process.env.AFRICASTALKING_API_KEY && process.env.AFRICASTALKING_USERNAME

        if (useRealSMS) {
            try {
                const AfricasTalking = require('africastalking')
                const client = AfricasTalking({
                    apiKey: process.env.AFRICASTALKING_API_KEY!,
                    username: process.env.AFRICASTALKING_USERNAME!,
                })

                const result = await client.SMS.send({
                    to: [phone],
                    message,
                    from: 'GateKeeper'
                })

                console.log('[SMS] Sent via Africa\'s Talking:', result.SMSMessageData.Recipients[0].status)
                return result.SMSMessageData.Recipients[0].status === 'Success'
            } catch (error) {
                console.error('[SMS] Africa\'s Talking error:', error)
                // Fall back to console logging
                console.log('[SMS] Falling back to console')
            }
        }

        // Development mode: Log to console
        console.log(`\n========== SMS MESSAGE ==========`)
        console.log(`To: ${phone}`)
        console.log(`Message: ${message}`)
        console.log(`=================================\n`)
        return true
    },

    async sendOTP(phone: string, code: string): Promise<boolean> {
        const message = `Your GateKeeper verification code is: ${code}. Valid for 10 minutes.`
        return await this.sendSMS(phone, message)
    }
}

export const OTPService = {
    generateOTP(): string {
        return Math.floor(100000 + Math.random() * 900000).toString()
    },

    async createOTP(phone: string, purpose: string): Promise<string> {
        // Check rate limiting (1 OTP per minute)
        const recentOTP = await prisma.otpVerification.findFirst({
            where: {
                phone,
                createdAt: {
                    gte: new Date(Date.now() - 60000) // Last 60 seconds
                }
            }
        })

        if (recentOTP) {
            throw new Error('Please wait before requesting another OTP')
        }

        // Delete old unverified OTPs for this phone
        await prisma.otpVerification.deleteMany({
            where: { phone, verified: false }
        })

        // Generate and store OTP
        const code = this.generateOTP()
        const expiresAt = new Date(Date.now() + 10 * 60 * 1000) // 10 minutes

        await prisma.otpVerification.create({
            data: {
                phone,
                code,
                purpose,
                expiresAt
            }
        })

        // Send SMS
        await SMSService.sendOTP(phone, code)

        return code // Return code for development/testing
    },

    async verifyOTP(phone: string, code: string, purpose: string): Promise<boolean> {
        const otpRecord = await prisma.otpVerification.findFirst({
            where: {
                phone,
                purpose,
                verified: false
            },
            orderBy: {
                createdAt: 'desc'
            }
        })

        if (!otpRecord) {
            throw new Error('No OTP found for this phone number')
        }

        // Check expiry
        if (new Date() > otpRecord.expiresAt) {
            throw new Error('OTP has expired. Please request a new one.')
        }

        // Check attempts
        if (otpRecord.attempts >= 3) {
            throw new Error('Maximum verification attempts exceeded. Please request a new OTP.')
        }

        // Increment attempts
        await prisma.otpVerification.update({
            where: { id: otpRecord.id },
            data: { attempts: otpRecord.attempts + 1 }
        })

        // Verify code
        if (otpRecord.code !== code) {
            throw new Error('Invalid OTP code')
        }

        // Mark as verified
        await prisma.otpVerification.update({
            where: { id: otpRecord.id },
            data: { verified: true }
        })

        return true
    },

    async completePhoneVerification(phone: string): Promise<void> {
        // Update user's phoneVerified status
        const formattedPhone = this.formatPhone(phone)

        await prisma.user.updateMany({
            where: { phone: formattedPhone },
            data: { phoneVerified: true }
        })
    },

    validatePhoneFormat(phone: string): boolean {
        // Nigerian phone format: +234XXXXXXXXXX
        const nigeriaRegex = /^\+234[789]\d{9}$/
        return nigeriaRegex.test(phone.replace(/[\s-]/g, ''))
    },

    formatPhone(phone: string): string {
        // Remove all spaces and dashes
        let cleaned = phone.replace(/[\s-]/g, '')

        // If starts with 0, replace with +234
        if (cleaned.startsWith('0')) {
            cleaned = '+234' + cleaned.substring(1)
        }

        // If doesn't start with +, add +234
        if (!cleaned.startsWith('+')) {
            cleaned = '+234' + cleaned
        }

        return cleaned
    }
}
