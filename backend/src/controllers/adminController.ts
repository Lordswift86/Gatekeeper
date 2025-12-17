import { Request, Response } from 'express'
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

export const getPlatformStats = async (req: Request, res: Response) => {
    try {
        const [totalEstates, totalUsers, globalAds] = await Promise.all([
            prisma.estate.count(),
            prisma.user.count(),
            prisma.globalAd.findMany({ where: { isActive: true } })
        ])

        const adImpressions = globalAds.reduce((sum: number, ad: any) => sum + ad.impressions, 0)

        res.json({
            totalEstates,
            totalUsers,
            adImpressions
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
