import { Request, Response } from 'express'
import { OTPService } from '../services/smsService'

export const sendOTP = async (req: Request, res: Response) => {
    try {
        const { phone, purpose = 'registration' } = req.body

        if (!phone) {
            return res.status(400).json({ message: 'Phone number is required' })
        }

        // Format and validate phone
        const formattedPhone = OTPService.formatPhone(phone)
        if (!OTPService.validatePhoneFormat(formattedPhone)) {
            return res.status(400).json({ message: 'Invalid phone number format. Use Nigerian format: +234XXXXXXXXXX' })
        }

        // Create and send OTP
        const code = await OTPService.createOTP(formattedPhone, purpose)

        res.json({
            message: 'OTP sent successfully',
            phone: formattedPhone,
            // Include code in development for testing
            ...(process.env.NODE_ENV === 'development' && { code })
        })
    } catch (error: any) {
        res.status(400).json({ message: error.message || 'Failed to send OTP' })
    }
}

export const verifyOTP = async (req: Request, res: Response) => {
    try {
        const { phone, code, purpose = 'registration' } = req.body

        if (!phone || !code) {
            return res.status(400).json({ message: 'Phone number and code are required' })
        }

        const formattedPhone = OTPService.formatPhone(phone)
        const isValid = await OTPService.verifyOTP(formattedPhone, code, purpose)

        if (isValid) {
            // Mark phone as verified for the user
            await OTPService.completePhoneVerification(formattedPhone)

            res.json({
                message: 'OTP verified successfully',
                verified: true
            })
        }
    } catch (error: any) {
        res.status(400).json({ message: error.message || 'OTP verification failed' })
    }
}
