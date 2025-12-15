import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

// Add a sub-account linked to the current (primary) user
export const addSubAccount = async (req: any, res: Response) => {
    try {
        const primaryUserId = req.user.userId;
        const { name, email, password } = req.body;

        // 1. Verify Primary User Status
        const primaryUser = await prisma.user.findUnique({ where: { id: primaryUserId } });
        if (!primaryUser || primaryUser.primaryUserId) {
            return res.status(403).json({ message: 'Only primary account holders can add sub-accounts' });
        }

        // 2. Check duplicate email
        const existing = await prisma.user.findUnique({ where: { email } });
        if (existing) {
            return res.status(400).json({ message: 'Email already registered' });
        }

        // 3. Create Sub-Account
        const hashedPassword = await bcrypt.hash(password, 10);
        const subUser = await prisma.user.create({
            data: {
                name,
                email,
                password: hashedPassword,
                role: 'RESIDENT',
                estateId: primaryUser.estateId,
                unitNumber: primaryUser.unitNumber,
                isApproved: true, // Inherit approval from primary
                primaryUserId: primaryUser.id
            }
        });

        const { password: _, ...userWithoutPassword } = subUser;
        res.status(201).json(userWithoutPassword);
    } catch (error) {
        res.status(500).json({ message: 'Failed to create sub-account' });
    }
};

// Get all household members
export const getHousehold = async (req: any, res: Response) => {
    try {
        const userId = req.user.userId;

        // Only primary users can see manage/list household for management purposes
        // Sub-users typically don't manage the household
        const user = await prisma.user.findUnique({
            where: { id: userId },
            include: { subAccounts: true }
        });

        if (!user) return res.status(404).json({ message: 'User not found' });

        if (user.primaryUserId) {
            // If I am a sub-user, maybe I want to see who else is there? 
            // For now, let's restrict management list to primary.
            return res.status(403).json({ message: 'Only primary account holders can view household settings' });
        }

        // Return sub-accounts
        const sanitizedSubs = user.subAccounts.map(({ password, ...u }: { password: string, [key: string]: any }) => u);
        res.json(sanitizedSubs);
    } catch (error) {
        res.status(500).json({ message: 'Failed to fetch household' });
    }
};

// Remove a sub-account
export const removeSubAccount = async (req: any, res: Response) => {
    try {
        const primaryUserId = req.user.userId;
        const { subUserId } = req.params;

        const subUser = await prisma.user.findUnique({ where: { id: subUserId } });

        if (!subUser) return res.status(404).json({ message: 'User not found' });

        // Security check: Must belong to this primary user
        if (subUser.primaryUserId !== primaryUserId) {
            return res.status(403).json({ message: 'Not authorized to remove this user' });
        }

        await prisma.user.delete({ where: { id: subUserId } });
        res.json({ message: 'User removed from household' });
    } catch (error) {
        res.status(500).json({ message: 'Failed to remove user' });
    }
};
