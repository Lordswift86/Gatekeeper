import { Response } from 'express'
import { AuthRequest } from '../middleware/auth'
import { SecurityService } from '../services/securityService'

export const getLogs = async (req: AuthRequest, res: Response) => {
    const logs = await SecurityService.getEstateLogs(req.user!.estateId!)
    res.json(logs)
}

export const addManualLog = async (req: AuthRequest, res: Response) => {
    try {
        const log = await SecurityService.addManualLog(req.user!.estateId!, req.body)
        res.json(log)
    } catch (e: any) {
        res.status(400).json({ message: e.message })
    }
}

export const getAnnouncements = async (req: AuthRequest, res: Response) => {
    const announcements = await SecurityService.getAnnouncements(req.user!.estateId!)
    res.json(announcements)
}

export const createAnnouncement = async (req: AuthRequest, res: Response) => {
    if (req.user!.role !== 'ESTATE_ADMIN') return res.sendStatus(403)
    try {
        const announcement = await SecurityService.createAnnouncement(req.user!.estateId!, req.body)
        res.json(announcement)
    } catch (e: any) {
        res.status(400).json({ message: e.message })
    }
}
