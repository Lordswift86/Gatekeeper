import { Request, Response } from 'express'
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

export const getPlatformStats = async (req: Request, res: Response) => {
    try {
        const [activeEstates, totalUsers, globalAds] = await Promise.all([
            prisma.estate.count({ where: { status: 'ACTIVE' } }),
            prisma.user.count(),
            prisma.globalAd.findMany({ where: { isActive: true } })
        ])

        const adImpressions = globalAds.reduce((sum: number, ad: any) => sum + ad.impressions, 0)
        const adClicks = globalAds.reduce((sum: number, ad: any) => sum + (ad.clicks || 0), 0)

        res.json({
            totalEstates: activeEstates,
            totalUsers,
            adImpressions,
            adClicks
        })
    } catch (error: any) {
        res.status(500).json({ message: error.message })
    }
}

export const getSystemLogs = async (req: Request, res: Response) => {
    try {
        const logs = await prisma.systemLog.findMany({
            orderBy: { createdAt: 'desc' },
            take: parseInt(req.query.limit as string) || 50
        })
        res.json(logs)
    } catch (error: any) {
        res.status(500).json({ message: error.message })
    }
}
