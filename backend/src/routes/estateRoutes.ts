import { Router } from 'express'
import { getAllEstates, getEstateById, createEstate, updateEstate, toggleEstateStatus, getEstateStats } from '../controllers/estateController'
import { authenticateToken } from '../middleware/auth'

const router = Router()

router.get('/', authenticateToken, getAllEstates)
router.get('/stats', authenticateToken, getEstateStats)
router.get('/:id', authenticateToken, getEstateById)
router.post('/', authenticateToken, createEstate)
router.put('/:id', authenticateToken, updateEstate)
router.put('/:id/status', authenticateToken, toggleEstateStatus)

export default router
