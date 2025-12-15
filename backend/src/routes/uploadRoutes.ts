import express from 'express';
import { upload } from '../config/cloudinary';
import { PrismaClient } from '@prisma/client';
import { authenticateToken } from '../middleware/auth';

const router = express.Router();
const prisma = new PrismaClient();

// Upload Profile Photo
router.post('/profile-photo', authenticateToken, upload.single('photo'), async (req: any, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ message: 'No file uploaded' });
        }

        const photoUrl = req.file.path; // Cloudinary URL
        const userId = req.user.userId;

        // Update user profile
        const updatedUser = await prisma.user.update({
            where: { id: userId },
            data: { photoUrl },
        });

        res.json({
            message: 'Photo uploaded successfully',
            photoUrl: updatedUser.photoUrl,
        });
    } catch (error) {
        console.error('Upload Error:', error);
        res.status(500).json({ message: 'Upload failed' });
    }
});

export default router;
