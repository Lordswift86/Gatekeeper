import prisma from '../config/db'

export const GlobalAdService = {
    async getAllAds() {
        return prisma.globalAd.findMany({
            where: { isActive: true },
            orderBy: { createdAt: 'desc' }
        })
    },

    async createAd(data: {
        imageUrl: string
        targetUrl?: string
        startDate: Date
        endDate: Date
    }) {
        return prisma.globalAd.create({
            data: {
                imageUrl: data.imageUrl,
                targetUrl: data.targetUrl,
                startDate: data.startDate,
                endDate: data.endDate,
                isActive: true
            }
        })
    },

    async updateAd(id: string, data: {
        imageUrl?: string
        targetUrl?: string
        startDate?: Date
        endDate?: Date
        isActive?: boolean
    }) {
        return prisma.globalAd.update({
            where: { id },
            data
        })
    },

    async deleteAd(id: string) {
        return prisma.globalAd.delete({
            where: { id }
        })
    },

    async incrementImpressions(id: string) {
        return prisma.globalAd.update({
            where: { id },
            data: {
                impressions: {
                    increment: 1
                }
            }
        })
    },

    async incrementClicks(id: string) {
        return prisma.globalAd.update({
            where: { id },
            data: {
                clicks: {
                    increment: 1
                }
            }
        })
    }
}
