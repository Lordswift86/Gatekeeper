import { Response } from 'express'
import { AuthRequest } from '../middleware/auth'
import { BillService } from '../services/billService'

export const getMyBills = async (req: AuthRequest, res: Response) => {
    const bills = await BillService.getMyBills(req.user!.userId)
    res.json(bills)
}

export const getEstateBills = async (req: AuthRequest, res: Response) => {
    if (req.user!.role !== 'ESTATE_ADMIN') return res.sendStatus(403)
    const bills = await BillService.getEstateBills(req.user!.estateId!)
    res.json(bills)
}

export const createBill = async (req: AuthRequest, res: Response) => {
    if (req.user!.role !== 'ESTATE_ADMIN') return res.sendStatus(403)
    try {
        const bill = await BillService.createBill({ ...req.body, estateId: req.user!.estateId })
        res.json(bill)
    } catch (e: any) {
        res.status(400).json({ message: e.message })
    }
}

export const payBill = async (req: AuthRequest, res: Response) => {
    // In real app, verify user owns bill or is admin
    try {
        const bill = await BillService.payBill(req.params.id)
        res.json(bill)
    } catch (e: any) {
        res.status(400).json({ message: e.message })
    }
}
