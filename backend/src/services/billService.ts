import { PrismaClient } from '@prisma/client'
import prisma from '../config/db'

export const BillService = {
    async getMyBills(userId: string) {
        // Find if user is primary or sub
        const user = await prisma.user.findUnique({
            where: { id: userId },
            include: { subAccounts: true }
        });

        if (!user) return [];

        const householdIds = [user.id];

        if (user.primaryUserId) {
            // I am a sub-account, also fetch bills for my primary
            householdIds.push(user.primaryUserId);
        } else {
            // I am primary, fetch bills for all my sub-accounts
            user.subAccounts.forEach((sub: any) => householdIds.push(sub.id));
        }

        return prisma.bill.findMany({
            where: { userId: { in: householdIds } },
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
