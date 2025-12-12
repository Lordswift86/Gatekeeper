import { Request, Response } from 'express'
import { EstateService } from '../services/estateService'

export const getAllEstates = async (req: Request, res: Response) => {
    try {
        const estates = await EstateService.getAllEstates()
        res.json(estates)
    } catch (error: any) {
        res.status(500).json({ message: error.message })
    }
}

export const getEstateById = async (req: Request, res: Response) => {
    try {
        const estate = await EstateService.getEstateById(req.params.id)
        if (!estate) {
            return res.status(404).json({ message: 'Estate not found' })
        }
        res.json(estate)
    } catch (error: any) {
        res.status(500).json({ message: error.message })
    }
}

export const createEstate = async (req: Request, res: Response) => {
    try {
        const estate = await EstateService.createEstate(req.body)
        res.status(201).json(estate)
    } catch (error: any) {
        res.status(500).json({ message: error.message })
    }
}

export const updateEstate = async (req: Request, res: Response) => {
    try {
        const estate = await EstateService.updateEstate(req.params.id, req.body)
        res.json(estate)
    } catch (error: any) {
        res.status(500).json({ message: error.message })
    }
}

export const toggleEstateStatus = async (req: Request, res: Response) => {
    try {
        const estate = await EstateService.toggleEstateStatus(req.params.id)
        res.json(estate)
    } catch (error: any) {
        res.status(500).json({ message: error.message })
    }
}

export const getEstateStats = async (req: Request, res: Response) => {
    try {
        const estateId = (req as any).user.estateId
        if (!estateId) {
            return res.status(400).json({ message: 'No estate associated with user' })
        }

        const stats = await EstateService.getEstateStats(estateId)
        res.json(stats)
    } catch (error: any) {
        res.status(500).json({ message: error.message })
    }
}
