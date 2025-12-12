import prisma from '../config/db'

export const GlobalAdService = {
    async getAllAds() {
        return prisma.globalAd.findMany({
            orderBy: { createdAt: 'desc' }
        })
    },

    async createAd(data: { title: string, content: string, imageUrl?: string }) {
        return prisma.globalAd.create({
            data: {
                title: data.title,
                content: data.content,
                imageUrl: data.imageUrl,
                isActive: true,
                impressions: 0
            }
        })
    },

    async updateAd(id: string, data: { title?: string, content?: string, imageUrl?: string, isActive?: boolean }) {
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
    }
}
