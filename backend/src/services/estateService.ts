import prisma from '../config/db'

import bcrypt from 'bcryptjs'

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

    async updateEstate(id: string, data: { name?: string, tier?: string, securityPhone?: string, securityPassword?: string }) {
        // If security contact is being updated and password is provided, create/update security account
        if (data.securityPhone && data.securityPassword) {
            const hashedPassword = await bcrypt.hash(data.securityPassword, 12)

            // Format phone number to match login expectation
            const { OTPService } = require('./smsService')
            const formattedPhone = OTPService.formatPhone(data.securityPhone)

            // defined role for security
            const role = 'SECURITY'

            // Check if user exists
            const existingUser = await prisma.user.findFirst({
                where: { phone: formattedPhone }
            })

            if (existingUser) {
                // Update existing user to be security (or at least update password if already security)
                await prisma.user.update({
                    where: { id: existingUser.id },
                    data: {
                        password: hashedPassword,
                        phoneVerified: true
                    }
                })
            } else {
                // Create new security user
                await prisma.user.create({
                    data: {
                        name: 'Estate Security',
                        phone: formattedPhone,
                        password: hashedPassword,
                        role: role,
                        estateId: id,
                        isApproved: true,
                        phoneVerified: true
                    }
                })
            }
        }

        // Remove securityPassword from data before updating estate (it's not part of estate model)
        const { securityPassword, ...estateData } = data

        return prisma.estate.update({
            where: { id },
            data: estateData
        })
    },

    async toggleEstateStatus(id: string) {
        const estate = await prisma.estate.findUnique({
            where: { id },
            include: {
                users: {
                    where: { role: 'ESTATE_ADMIN' }
                }
            }
        })

        if (!estate) throw new Error('Estate not found')

        // Determine new status
        let newStatus: string
        if (estate.status === 'PENDING') {
            // Activating a pending estate
            newStatus = 'ACTIVE'

            // Also approve all estate admin users for this estate
            if (estate.users.length > 0) {
                await prisma.user.updateMany({
                    where: {
                        estateId: id,
                        role: 'ESTATE_ADMIN'
                    },
                    data: { isApproved: true }
                })
            }
        } else {
            // Toggle between ACTIVE and SUSPENDED
            newStatus = estate.status === 'ACTIVE' ? 'SUSPENDED' : 'ACTIVE'
        }

        return prisma.estate.update({
            where: { id },
            data: { status: newStatus }
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
