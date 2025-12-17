import { Request, Response } from 'express'
import { AuthRequest } from '../middleware/auth'
import { ReferralService } from '../services/referralService'

export const getReferralCode = async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user!.userId
        const referralCode = await ReferralService.getUserReferralCode(userId)
        res.json({ referralCode })
    } catch (error: any) {
        res.status(500).json({ message: error.message || 'Failed to get referral code' })
    }
}

export const getReferralStats = async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user!.userId
        const stats = await ReferralService.getReferralStats(userId)
        res.json(stats)
    } catch (error: any) {
        res.status(500).json({ message: error.message || 'Failed to get referral stats' })
    }
}
