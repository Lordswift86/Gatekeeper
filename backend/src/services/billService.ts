import prisma from '../config/db'

export const BillService = {
    async getMyBills(userId: string) {
        return prisma.bill.findMany({
            where: { userId },
            orderBy: { dueDate: 'asc' }
        })
    },

    async getEstateBills(estateId: string) {
        return prisma.bill.findMany({
            where: { estateId },
            include: { user: { select: { name: true, unitNumber: true } } },
            orderBy: { dueDate: 'desc' }
        })
    },

    async createBill(data: { estateId: string, userId: string, type: string, amount: number, dueDate: string, description: string }) {
        return prisma.bill.create({
            data: {
                estateId: data.estateId,
                userId: data.userId,
                type: data.type,
                amount: data.amount,
                dueDate: new Date(data.dueDate),
                description: data.description,
                status: 'UNPAID'
            }
        })
    },

    async payBill(billId: string) {
        return prisma.bill.update({
            where: { id: billId },
            data: {
                status: 'PAID',
                paidAt: new Date()
            }
        })
    }
}
