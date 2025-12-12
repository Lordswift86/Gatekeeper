import prisma from '../config/db'

export const UserService = {
    async getProfile(userId: string) {
        const user = await prisma.user.findUnique({
            where: { id: userId },
            include: { estate: true }
        })

        // safe return
        if (!user) return null
        const { password, ...safeUser } = user
        return safeUser
    },

    async updateProfile(userId: string, data: { name?: string, unitNumber?: string }) {
        return prisma.user.update({
            where: { id: userId },
            data
        })
    },

    // Admin Methods
    async getPendingUsers(estateId: string) {
        return prisma.user.findMany({
            where: { estateId, isApproved: false }
        })
    },

    async approveUser(userId: string) {
        return prisma.user.update({
            where: { id: userId },
            data: { isApproved: true }
        })
    },

    async getAllUsers() {
        return prisma.user.findMany({
            select: {
                id: true,
                email: true,
                name: true,
                role: true,
                estateId: true,
                unitNumber: true,
                isApproved: true,
                createdAt: true,
                updatedAt: true
            }
        })
    },

    async getResidentsByEstate(estateId: string) {
        return prisma.user.findMany({
            where: {
                estateId,
                role: 'RESIDENT'
            }
        })
    },

    async deleteUser(userId: string) {
        return prisma.user.delete({ where: { id: userId } })
    }
}
