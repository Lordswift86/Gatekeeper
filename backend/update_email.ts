import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

async function main() {
    const oldEmail = 'admin@gatekeeper.com'
    const newEmail = 'admin@kitaniz.com'

    try {
        const user = await prisma.user.update({
            where: { email: oldEmail },
            data: { email: newEmail },
        })
        console.log(`Updated user ${user.id}: ${oldEmail} -> ${newEmail}`)
    } catch (e) {
        console.error('Error updating user (maybe already updated?):', e)
        // Check if new email already exists
        const newUser = await prisma.user.findUnique({ where: { email: newEmail } })
        if (newUser) {
            console.log('User with new email already exists.')
        }
    }
}

main()
    .catch((e) => {
        console.error(e)
        process.exit(1)
    })
    .finally(async () => {
        await prisma.$disconnect()
    })
