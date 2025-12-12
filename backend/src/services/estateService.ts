import prisma from '../config/db'

export const EstateService = {
    async getAllEstates() {
        return prisma.estate.findMany({
            include: {
                _count: {
                    select: {
                        users: true,
                        bills: true,
                    }
                }
            }
        })
    },

    async getEstateById(id: string) {
        return prisma.estate.findUnique({ where: { id } })
    },

    async createEstate(data: { name: string, code: string, tier: string }) {
        return prisma.estate.create({
            data: {
                name: data.name,
                code: data.code,
                subscriptionTier: data.tier,
                status: 'ACTIVE'
            }
        })
    },

    async updateEstate(id: string, data: { name?: string, tier?: string }) {
        return prisma.estate.update({
            where: { id },
            data
        })
    },

    async toggleEstateStatus(id: string) {
        const estate = await prisma.estate.findUnique({ where: { id } })
        if (!estate) throw new Error('Estate not found')

        return prisma.estate.update({
            where: { id },
            data: { status: estate.status === 'ACTIVE' ? 'SUSPENDED' : 'ACTIVE' }
        })
    },

    async getEstateStats(estateId: string) {
        const [totalResidents, pendingResidents, activePasses, unpaidBills] = await Promise.all([
            prisma.user.count({ where: { estateId, role: 'RESIDENT' } }),
            prisma.user.count({ where: { estateId, role: 'RESIDENT', isApproved: false } }),
            prisma.guestPass.count({ where: { host: { estateId }, status: 'ACTIVE' } }),
            prisma.bill.count({ where: { estateId, status: 'UNPAID' } })
        ])

        return {
            totalResidents,
            pendingResidents,
            activePasses,
            unpaidBills
        }
    }
}
