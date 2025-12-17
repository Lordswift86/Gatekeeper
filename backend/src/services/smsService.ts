import prisma from '../config/db'
import crypto from 'crypto'

// SMS Service with Africa's Talking and YourNotify integration
export const SMSService = {
    async sendViaAfricasTalking(phone: string, message: string): Promise<boolean> {
        const useRealSMS = process.env.AFRICASTALKING_API_KEY && process.env.AFRICASTALKING_USERNAME

        if (!useRealSMS) {
            console.log('[SMS-AT] Credentials missing, skipping Africa\'s Talking')
            return false
        }

        try {
            const AfricasTalking = require('africastalking')
            const client = AfricasTalking({
                apiKey: process.env.AFRICASTALKING_API_KEY!,
                username: process.env.AFRICASTALKING_USERNAME!,
            })

            const result = await client.SMS.send({
                to: [phone],
                message,
                from: process.env.AFRICASTALKING_SENDER_ID
            })

            const status = result.SMSMessageData.Recipients[0].status
            console.log(`[SMS-AT] Sent via Africa's Talking: ${status}`)
            return status === 'Success'
        } catch (error) {
            console.error(`[SMS-AT] Error:`, error)
            return false
        }
    },

    async sendViaYourNotify(phone: string, message: string): Promise<boolean> {
        const useRealSMS = process.env.YOURNOTIFY_API_KEY && process.env.YOURNOTIFY_SENDER_ID

        if (!useRealSMS) {
            console.log('[SMS-YN] Credentials missing, skipping YourNotify')
            return false
        }

        try {
            // Correct endpoint based on yournotify-node-sdk analysis
            const response = await fetch('https://api.yournotify.com/campaigns/sms', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${process.env.YOURNOTIFY_API_KEY}`
                },
                body: JSON.stringify({
                    name: "GateKeeper SMS",
                    from: process.env.YOURNOTIFY_SENDER_ID,
                    text: message,
                    status: "running",
                    channel: "sms",
                    lists: [phone]
                })
            })

            if (!response.ok) {
                const errorText = await response.text()
                console.error(`[SMS-YN] API Error (${response.status}):`, errorText)
                return false
            }

            const data = await response.json()
            console.log(`[SMS-YN] Sent via YourNotify:`, data)
            return true
        } catch (error) {
            console.error(`[SMS-YN] Error:`, error)
            return false
        }
    },

    async sendSMS(phone: string, message: string): Promise<boolean> {
        console.log(`\n========== SMS BROADCAST ==========`)
        console.log(`To: ${phone}`)
        console.log(`Message: ${message}`)
        console.log(`===================================`)

        if (process.env.NODE_ENV === 'development' && !process.env.AFRICASTALKING_API_KEY && !process.env.YOURNOTIFY_API_KEY) {
            console.log('[SMS] Development mode (no credentials): Logs only')
            return true
        }

        // Attempt to send via both providers in parallel
        const [atResult, ynResult] = await Promise.all([
            this.sendViaAfricasTalking(phone, message),
            this.sendViaYourNotify(phone, message)
        ])

        const success = atResult || ynResult

        if (success) {
            console.log(`[SMS] Broadcast successful (AT: ${atResult}, YN: ${ynResult})`)
        } else {
            console.error(`[SMS] Broadcast failed (AT: ${atResult}, YN: ${ynResult})`)
        }

        return success
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
        if (!phone) return false
        // Nigerian phone format: +234XXXXXXXXXX
        const nigeriaRegex = /^\+234[789]\d{9}$/
        return nigeriaRegex.test(phone.replace(/[\s-]/g, ''))
    },

    formatPhone(phone: string): string {
        console.log('[SMS] Formatting phone:', phone)
        if (!phone) throw new Error('Phone number is missing')
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
console.log('✅ SMS Service Module Loaded')
