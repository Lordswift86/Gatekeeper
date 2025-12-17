import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

async function checkDatabase() {
    console.log('📊 Database Statistics:\n')

    const estates = await prisma.estate.count()
    const users = await prisma.user.count()
    const accessPasses = await prisma.guestPass.count()
    const otps = await prisma.otpVerification.count()
    const bills = await prisma.bill.count()

    console.log(`Estates: ${estates}`)
    console.log(`Users: ${users}`)
    console.log(`Access Passes: ${accessPasses}`)
    console.log(`OTP Verifications: ${otps}`)
    console.log(`Bills: ${bills}`)

    console.log('\n📋 Sample Users:')
    const sampleUsers = await prisma.user.findMany({
        take: 5,
        select: {
            name: true,
            email: true,
            role: true,
            phoneVerified: true
        }
    })
    console.table(sampleUsers)

    console.log('\n🏠 Sample Estates:')
    const sampleEstates = await prisma.estate.findMany({
        select: {
            name: true,
            address: true,
            _count: {
                select: { users: true }
            }
        }
    })
    console.table(sampleEstates)
}

checkDatabase()
    .catch(console.error)
    .finally(() => prisma.$disconnect())
