import { Router } from 'express'
import { getMyBills, getEstateBills, createBill, payBill } from '../controllers/billController'
import { authenticateToken } from '../middleware/auth'

const router = Router()
router.use(authenticateToken)

router.get('/my', getMyBills)
router.get('/estate', getEstateBills)
router.post('/', createBill)
router.post('/:id/pay', payBill)

export default router
