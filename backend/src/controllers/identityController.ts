
import { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || 'secret';

interface IdentityPayload {
    id: string;
    type: 'RESIDENT_ID';
    iat: number;
    exp: number;
}

export const getIdentityToken = async (req: any, res: Response) => {
    try {
        const userId = req.user.id;
        const user = await prisma.user.findUnique({
            where: { id: userId },
            include: { estate: true }
        });

        if (!user) return res.status(404).json({ message: 'User not found' });
        if (user.role !== 'RESIDENT') return res.status(403).json({ message: 'Only residents have digital IDs' });

        // Generate a short-lived token (5 minutes) specifically for ID verification
        const token = jwt.sign(
            { id: user.id, type: 'RESIDENT_ID' },
            JWT_SECRET,
            { expiresIn: '5m' }
        );

        res.json({
            token,
            validUntil: Date.now() + 5 * 60 * 1000 // 5 mins
        });
    } catch (error) {
        res.status(500).json({ message: 'Failed to generate ID token' });
    }
};

export const verifyIdentity = async (req: any, res: Response) => {
    try {
        const { token } = req.body;
        if (!token) return res.status(400).json({ message: 'Token required' });

        // 1. Verify JWT signature and expiration
        let payload: IdentityPayload;
        try {
            payload = jwt.verify(token, JWT_SECRET) as IdentityPayload;
        } catch (e) {
            return res.status(401).json({ message: 'Invalid or expired ID token' });
        }

        if (payload.type !== 'RESIDENT_ID') {
            return res.status(400).json({ message: 'Invalid token type' });
        }

        // 2. Check Database for real-time status
        const user = await prisma.user.findUnique({
            where: { id: payload.id },
            include: { estate: true }
        });

        if (!user) return res.status(404).json({ message: 'User not found' });

        // 3. Security Checks
        if (!user.isApproved) return res.status(403).json({ message: 'Resident account is not approved' });
        if (user.estate?.status === 'SUSPENDED') return res.status(403).json({ message: 'Estate service suspended' });

        // 4. Return Verification Data
        res.json({
            verified: true,
            user: {
                id: user.id,
                name: user.name,
                unitNumber: user.unitNumber,
                photoUrl: user.photoUrl,
                role: user.role,
                estateName: user.estate?.name,
                status: 'ACTIVE'
            }
        });
    } catch (error) {
        res.status(500).json({ message: 'Verification failed' });
    }
};
