import prisma from '../config/db'
import crypto from 'crypto'

export const ReferralService = {
    /**
     * Generate a unique referral code for a user
     * Format: [NAME]-[RANDOM] e.g. EMMIE-A1B2C3
     */
    generateReferralCode(name: string): string {
        const namePart = name.toUpperCase().replace(/[^A-Z]/g, '').substring(0, 5)
        const randomPart = crypto.randomBytes(3).toString('hex').toUpperCase().substring(0, 6)
        return `${namePart}-${randomPart}`
    },

    /**
     * Get or create a user's referral code
     */
    async getUserReferralCode(userId: string): Promise<string> {
        const user = await prisma.user.findUnique({ where: { id: userId } })
        if (!user) throw new Error('User not found')

        // Return existing code if present
        if (user.referralCode) {
            return user.referralCode
        }

        // Generate new unique code
        let referralCode = this.generateReferralCode(user.name)
        let attempts = 0

        // Ensure uniqueness
        while (attempts < 10) {
            const existing = await prisma.user.findUnique({ where: { referralCode } })
            if (!existing) break
            referralCode = this.generateReferralCode(user.name)
            attempts++
        }

        // Save to database
        await prisma.user.update({
            where: { id: userId },
            data: { referralCode }
        })

        return referralCode
    },

    /**
     * Validate a referral code exists
     */
    async validateReferralCode(code: string): Promise<boolean> {
        const user = await prisma.user.findUnique({ where: { referralCode: code } })
        return user !== null
    },

    /**
     * Get user's referral statistics
     */
    async getReferralStats(userId: string) {
        const user = await prisma.user.findUnique({
            where: { id: userId },
            include: {
                referrals: {
                    select: {
                        id: true,
                        name: true,
                        createdAt: true,
                        role: true
                    }
                }
            }
        })

        if (!user) throw new Error('User not found')

        return {
            referralCode: user.referralCode || await this.getUserReferralCode(userId),
            totalReferrals: user.referrals.length,
            referrals: user.referrals
        }
    },

    /**
     * Link a new user to their referrer
     */
    async linkReferral(newUserId: string, referralCode: string): Promise<void> {
        const referrer = await prisma.user.findUnique({ where: { referralCode } })
        if (!referrer) throw new Error('Invalid referral code')

        await prisma.user.update({
            where: { id: newUserId },
            data: { referredBy: referrer.id }
        })
    }
}
