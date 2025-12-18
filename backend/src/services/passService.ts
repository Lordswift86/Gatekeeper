import prisma from '../config/db'

export const PassService = {
    async generatePass(userId: string, data: { guestName: string, type: string, validUntil?: string, exitInstruction?: string, deliveryCompany?: string }) {
        // Generate 5 digit code
        const code = Math.floor(10000 + Math.random() * 90000).toString()

        // Calculate validity if not provided
        let validUntilDate = new Date()
        if (data.validUntil) {
            validUntilDate = new Date(data.validUntil)
        } else {
            // Defaults
            if (data.type === 'ONE_TIME') validUntilDate.setHours(validUntilDate.getHours() + 12)
            if (data.type === 'RECURRING') validUntilDate.setDate(validUntilDate.getDate() + 30)
            if (data.type === 'DELIVERY') validUntilDate.setMinutes(validUntilDate.getMinutes() + 30)
        }

        return prisma.guestPass.create({
            data: {
                hostId: userId,
                guestName: data.guestName,
                type: data.type || 'ONE_TIME',
                code,
                status: 'ACTIVE',
                validUntil: validUntilDate,
                exitInstruction: data.exitInstruction,
                deliveryCompany: data.deliveryCompany
            }
        })
    },

    async getMyPasses(userId: string) {
        return prisma.guestPass.findMany({
            where: { hostId: userId },
            orderBy: { createdAt: 'desc' },
            include: { host: true }
        })
    },

    async getEstatePasses(estateId: string) {
        return prisma.guestPass.findMany({
            where: {
                host: { estateId: estateId }
            },
            orderBy: { createdAt: 'desc' },
            include: { host: true }
        })
    },

    async validateCode(code: string, estateId: string) {
        const pass = await prisma.guestPass.findUnique({
            where: { code },
            include: { host: true }
        })

        if (!pass) return { success: false, message: 'Invalid Code' }

        if (pass.host.estateId !== estateId) {
            return { success: false, message: 'Code belongs to different estate' }
        }

        if (pass.status === 'CANCELLED') return { success: false, message: 'Code Cancelled' }
        if (pass.status === 'EXPIRED' || pass.validUntil < new Date()) {
            return { success: false, message: 'Code Expired' }
        }

        return { success: true, pass }
    },

    async processEntry(passId: string) {
        console.log(`[PassService] processEntry called for passId: ${passId}`);
        const updated = await prisma.guestPass.update({
            where: { id: passId },
            data: {
                status: 'CHECKED_IN',
                entryTime: new Date()
            }
        })
        return updated
    },

    async processExit(passId: string) {
        const pass = await prisma.guestPass.findUnique({ where: { id: passId } })
        if (!pass) throw new Error('Pass not found')

        const newStatus = pass.type === 'RECURRING' ? 'ACTIVE' : 'EXPIRED'

        return prisma.guestPass.update({
            where: { id: passId },
            data: {
                status: newStatus,
                exitTime: new Date()
            }
        })
    },

    async cancelPass(passId: string, userId: string) {
        const pass = await prisma.guestPass.findUnique({ where: { id: passId } })
        if (!pass) throw new Error('Pass not found')

        if (pass.hostId !== userId) throw new Error('Unauthorized to cancel this pass')

        return prisma.guestPass.update({
            where: { id: passId },
            data: { status: 'CANCELLED' }
        })
    }
}
