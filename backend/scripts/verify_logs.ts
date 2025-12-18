
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

async function main() {
    console.log('--- Verifying Logs ---')

    // 1. Check the specific pass
    const code = '72094'
    const pass = await prisma.guestPass.findUnique({
        where: { code },
        include: { host: true }
    })

    if (!pass) {
        console.log(`Pass with code ${code} NOT FOUND`)
    } else {
        console.log(`Pass ${code} found:`)
        console.log(`- ID: ${pass.id}`)
        console.log(`- Status: ${pass.status}`)
        console.log(`- Entry Time: ${pass.entryTime}`)
        console.log(`- Host Estate ID: ${pass.host?.estateId}`)
    }

    // 2. Check recent logs for this estate (if pass exists)
    if (pass?.host?.estateId) {
        const estateId = pass.host.estateId
        console.log(`\nChecking logs for Estate: ${estateId}`)

        const manualLogs = await prisma.logEntry.findMany({
            where: { estateId },
            orderBy: { entryTime: 'desc' },
            take: 5
        })
        console.log(`Found ${manualLogs.length} manual logs`)

        const digitalLogs = await prisma.guestPass.findMany({
            where: {
                host: { estateId },
                entryTime: { not: null }
            },
            orderBy: { entryTime: 'desc' },
            take: 5
        })
        console.log(`Found ${digitalLogs.length} digital logs (Passes with entryTime)`)
        if (digitalLogs.length > 0) {
            console.log('Recent digital log:', digitalLogs[0])
        }
    }
}

main()
    .catch(e => console.error(e))
    .finally(async () => await prisma.$disconnect())
