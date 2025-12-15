import express from 'express';
import { addSubAccount, getHousehold, removeSubAccount } from '../controllers/householdController';
import { authenticateToken } from '../middleware/auth';

const router = express.Router();

// All routes require authentication
router.use(authenticateToken);

router.get('/', getHousehold);
router.post('/', addSubAccount);
router.delete('/:subUserId', removeSubAccount);

export default router;
