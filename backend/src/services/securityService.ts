import prisma from '../config/db'

export const SecurityService = {
    async getEstateLogs(estateId: string) {
        return prisma.logEntry.findMany({
            where: { estateId },
            orderBy: { entryTime: 'desc' },
            take: 100
        })
    },

    async addManualLog(estateId: string, data: { guestName: string, destination: string, notes?: string }) {
        return prisma.logEntry.create({
            data: {
                estateId,
                guestName: data.guestName,
                destination: data.destination,
                type: 'MANUAL',
                notes: data.notes,
                entryTime: new Date()
            }
        })
    },

    async getAnnouncements(estateId: string) {
        return prisma.announcement.findMany({
            where: { estateId },
            orderBy: { createdAt: 'desc' }
        })
    },

    async createAnnouncement(estateId: string, data: { title: string, content: string }) {
        return prisma.announcement.create({
            data: {
                estateId,
                title: data.title,
                content: data.content
            }
        })
    },

    async triggerSOS(estateId: string, userId: string, location?: string) {
        // High priority log
        return prisma.logEntry.create({
            data: {
                estateId,
                type: 'EMERGENCY',
                guestName: 'SOS ALERT',
                destination: location || 'Unknown Location',
                notes: `Emergency triggered by resident ${userId}`,
                entryTime: new Date()
            }
        })
    }
}
