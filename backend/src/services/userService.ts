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
        const user = await prisma.user.findUnique({
            where: { id: userId },
            include: { estate: true }
        })

        if (!user) throw new Error('User not found')

        // If user is an ESTATE_ADMIN, also activate their estate
        if (user.role === 'ESTATE_ADMIN' && user.estateId) {
            await prisma.estate.update({
                where: { id: user.estateId },
                data: { status: 'ACTIVE' }
            })
        }

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
    },

    async createSecurityAccount(data: {
        name: string;
        email: string;
        password: string;
        estateId: string;
    }) {
        const { name, email, password, estateId } = data

        // Check if email already exists
        const existingUser = await prisma.user.findUnique({ where: { email } })
        if (existingUser) throw new Error('Email already exists')

        // Verify estate exists
        const estate = await prisma.estate.findUnique({ where: { id: estateId } })
        if (!estate) throw new Error('Estate not found')

        // Hash password
        const bcrypt = require('bcryptjs')
        const hashedPassword = await bcrypt.hash(password, 12)

        // Create security account with auto-approval
        const user = await prisma.user.create({
            data: {
                name,
                email,
                password: hashedPassword,
                role: 'SECURITY',
                estateId,
                isApproved: true // Auto-approved since created by admin
            }
        })

        const { password: _, ...userWithoutPassword } = user
        return userWithoutPassword
    }
}
