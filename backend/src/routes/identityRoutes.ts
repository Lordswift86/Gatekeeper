
import express from 'express';
import { getIdentityToken, verifyIdentity } from '../controllers/identityController';
import { authenticateToken } from '../middleware/auth';

const router = express.Router();

// Generate ID Token (Resident only)
router.get('/token', authenticateToken, getIdentityToken);

// Verify ID Token (Security only - typically)
// In practice, security app calls this. We verify the scanner has auth too.
router.post('/verify', authenticateToken, verifyIdentity);

export default router;
