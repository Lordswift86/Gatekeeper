import { PrismaClient } from '@prisma/client'
import * as bcrypt from 'bcryptjs'

const prisma = new PrismaClient()

async function main() {
    // --- Clean DB ---
    await prisma.systemLog.deleteMany()
    await prisma.globalAd.deleteMany()
    await prisma.emergencyAlert.deleteMany()
    await prisma.chatMessage.deleteMany()
    await prisma.intercomSession.deleteMany()
    await prisma.bill.deleteMany()
    await prisma.logEntry.deleteMany()
    await prisma.guestPass.deleteMany()
    await prisma.user.deleteMany()
    await prisma.announcement.deleteMany()
    await prisma.estate.deleteMany()

    console.log('Cleaned database')

    // --- Password ---
    const password = await bcrypt.hash('password123', 10)

    // --- ESTATES ---
    const estates = await Promise.all([
        prisma.estate.create({
            data: {
                id: 'est_1',
                name: 'Sunset Gardens',
                code: 'SUN01',
                subscriptionTier: 'FREE',
                status: 'ACTIVE'
            }
        }),
        prisma.estate.create({
            data: {
                id: 'est_2',
                name: 'Royal Heights',
                code: 'ROY02',
                subscriptionTier: 'PREMIUM',
                status: 'ACTIVE'
            }
        }),
        prisma.estate.create({
            data: {
                id: 'est_3',
                name: 'Palm Springs',
                code: 'PLM03',
                subscriptionTier: 'FREE',
                status: 'SUSPENDED'
            }
        })
    ])
    console.log('Seeded Estates')

    // --- USERS ---
    const users = await Promise.all([
        // Super Admin
        prisma.user.create({
            data: {
                id: 'u_0',
                name: 'Super Admin',
                email: 'admin@kitaniz.com',
                role: 'SUPER_ADMIN',
                password,
                isApproved: true
            }
        }),
        // Estate Admin
        prisma.user.create({
            data: {
                id: 'u_1',
                name: 'Alice Admin',
                email: 'alice@sunset.com',
                role: 'ESTATE_ADMIN',
                estateId: 'est_1',
                password,
                isApproved: true
            }
        }),
        // Resident
        prisma.user.create({
            data: {
                id: 'u_2',
                name: 'Bob Resident',
                email: 'bob@sunset.com',
                role: 'RESIDENT',
                estateId: 'est_1',
                unitNumber: '101',
                password,
                isApproved: true
            }
        }),
        // Security
        prisma.user.create({
            data: {
                id: 'u_3',
                name: 'Sam Security',
                email: 'sam@sunset.com',
                role: 'SECURITY',
                estateId: 'est_1',
                password,
                isApproved: true
            }
        }),
        // Premium Resident
        prisma.user.create({
            data: {
                id: 'u_4',
                name: 'Richie Rich',
                email: 'richie@royal.com',
                role: 'RESIDENT',
                estateId: 'est_2',
                unitNumber: 'PH-1',
                password,
                isApproved: true
            }
        })
    ])
    console.log('Seeded Users')

    // --- PASSES ---
    const now = new Date()
    const oneHour = 60 * 60 * 1000

    await prisma.guestPass.create({
        data: {
            id: 'p_1',
            code: '12345',
            hostId: 'u_2',
            guestName: 'John Doe',
            hostUnit: '101',
            status: 'ACTIVE',
            type: 'ONE_TIME',
            validFrom: new Date(now.getTime() - oneHour),
            validUntil: new Date(now.getTime() + oneHour * 11),
            exitInstruction: 'Leaving with a heavy box.'
        }
    })

    await prisma.guestPass.create({
        data: {
            id: 'p_2',
            code: '54321',
            hostId: 'u_2',
            guestName: 'Jane Smith',
            hostUnit: '101',
            status: 'CHECKED_IN',
            type: 'ONE_TIME',
            validFrom: new Date(now.getTime() - oneHour * 2),
            validUntil: new Date(now.getTime() + oneHour * 10),
            entryTime: new Date(now.getTime() - oneHour / 2)
        }
    })
    console.log('Seeded Passes')

    // --- BILLS ---
    await prisma.bill.create({
        data: {
            id: 'b_1',
            estateId: 'est_1',
            userId: 'u_2',
            type: 'SERVICE_CHARGE',
            amount: 150.00,
            dueDate: new Date(now.getTime() - 86400000 * 35),
            status: 'UNPAID',
            description: 'September 2023 Service Charge'
        }
    })

    // --- ANNOUNCEMENTS ---
    await prisma.announcement.create({
        data: {
            id: 'a_1',
            estateId: 'est_1',
            title: 'Gate Maintenance',
            content: 'Main gate will be closed for 1 hour on Tuesday.',
        }
    })

    // --- GLOBAL ADS ---
    await prisma.globalAd.create({
        data: {
            id: 'ad_1',
            title: 'Kitaniz Vehicle Registration service',
            content: 'Renew Vehicle Documents, New Registration',
            impressions: 1450,
            isActive: true
        }
    })

    console.log('Seeded Logic Completed')
}

main()
    .catch((e) => {
        console.error(e)
        process.exit(1)
    })
    .finally(async () => {
        await prisma.$disconnect()
    })
