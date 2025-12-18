import prisma from '../config/db'

export const SecurityService = {
    async getEstateLogs(estateId: string) {
        // 1. Fetch Manual Logs
        const manualLogs = await prisma.logEntry.findMany({
            where: { estateId },
            orderBy: { entryTime: 'desc' },
            take: 50
        })

        // 2. Fetch Digital Logs (Guest Passes with entryTime)
        const digitalLogs = await prisma.guestPass.findMany({
            where: {
                host: { estateId },
                entryTime: { not: null }
            },
            include: { host: true },
            orderBy: { entryTime: 'desc' },
            take: 50
        })

        console.log(`[SecurityService] Found ${manualLogs.length} manual logs and ${digitalLogs.length} digital logs for estate ${estateId}`);
        if (digitalLogs.length > 0) {
            console.log('[SecurityService] First digital log:', digitalLogs[0]);
        }

        // 3. Map Digital Logs to match LogEntry structure
        const mappedDigitalLogs = digitalLogs.map(pass => ({
            id: pass.id,
            estateId: pass.host.estateId!,
            guestName: pass.guestName,
            destination: pass.hostUnit || pass.host.unitNumber || 'Unknown Unit',
            entryTime: pass.entryTime!,
            exitTime: pass.exitTime,
            type: 'DIGITAL',
            notes: `${pass.type} PASS - ${pass.code}`
        }))

        // 4. Merge and Sort
        const allLogs = [...manualLogs, ...mappedDigitalLogs]
        allLogs.sort((a, b) => b.entryTime.getTime() - a.entryTime.getTime())

        return allLogs.slice(0, 100)
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
