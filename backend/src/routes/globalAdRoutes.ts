import { Router } from 'express'
import { getAllAds, createAd, updateAd, deleteAd } from '../controllers/globalAdController'
import { authenticateToken } from '../middleware/auth'

const router = Router()

router.get('/', authenticateToken, getAllAds)
router.post('/', authenticateToken, createAd)
router.put('/:id', authenticateToken, updateAd)
router.delete('/:id', authenticateToken, deleteAd)

export default router
