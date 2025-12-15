import { Router } from 'express'
import { authenticateToken, requireEstateAdmin } from '../middleware/auth'
import prisma from '../config/db'

const router = Router()

// Transfer admin role to another user in the estate
router.post('/transfer-admin', authenticateToken, requireEstateAdmin, async (req, res) => {
    try {
        const currentUserId = (req as any).user.userId
        const { newAdminUserId } = req.body

        if (!newAdminUserId) {
            return res.status(400).json({ message: 'newAdminUserId is required' })
        }

        // Get current admin user
        const currentAdmin = await prisma.user.findUnique({
            where: { id: currentUserId },
            select: { estateId: true, role: true }
        })

        if (!currentAdmin || currentAdmin.role !== 'ESTATE_ADMIN') {
            return res.status(403).json({ message: 'Only estate admin can transfer role' })
        }

        // Verify new admin exists and is in the same estate
        const newAdmin = await prisma.user.findUnique({
            where: { id: newAdminUserId },
            select: { id: true, estateId: true, isApproved: true }
        })

        if (!newAdmin) {
            return res.status(404).json({ message: 'Target user not found' })
        }

        if (newAdmin.estateId !== currentAdmin.estateId) {
            return res.status(400).json({ message: 'Target user must be in the same estate' })
        }

        if (!newAdmin.isApproved) {
            return res.status(400).json({ message: 'Target user must be approved first' })
        }

        // Perform transfer in transaction
        await prisma.$transaction([
            // Promote new admin
            prisma.user.update({
                where: { id: newAdminUserId },
                data: { role: 'ESTATE_ADMIN' }
            }),
            // Demote current admin to resident
            prisma.user.update({
                where: { id: currentUserId },
                data: { role: 'RESIDENT' }
            })
        ])

        res.json({
            message: 'Admin role transferred successfully',
            newAdminId: newAdminUserId
        })
    } catch (error: any) {
        res.status(500).json({ message: error.message || 'Transfer failed' })
    }
})

export default router
