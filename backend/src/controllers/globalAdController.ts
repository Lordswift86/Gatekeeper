import { Request, Response } from 'express'
import { GlobalAdService } from '../services/globalAdService'

export const getAllAds = async (req: Request, res: Response) => {
    try {
        const ads = await GlobalAdService.getAllAds()
        res.json(ads)
    } catch (error: any) {
        res.status(500).json({ message: error.message })
    }
}

export const createAd = async (req: Request, res: Response) => {
    try {
        const ad = await GlobalAdService.createAd(req.body)
        res.status(201).json(ad)
    } catch (error: any) {
        res.status(500).json({ message: error.message })
    }
}

export const updateAd = async (req: Request, res: Response) => {
    try {
        const ad = await GlobalAdService.updateAd(req.params.id, req.body)
        res.json(ad)
    } catch (error: any) {
        res.status(500).json({ message: error.message })
    }
}

export const deleteAd = async (req: Request, res: Response) => {
    try {
        await GlobalAdService.deleteAd(req.params.id)
        res.status(204).send()
    } catch (error: any) {
        res.status(500).json({ message: error.message })
    }
}

export const trackImpression = async (req: Request, res: Response) => {
    try {
        const ad = await GlobalAdService.incrementImpressions(req.params.id)
        res.json(ad)
    } catch (error: any) {
        res.status(500).json({ message: error.message })
    }
}

export const trackClick = async (req: Request, res: Response) => {
    try {
        const ad = await GlobalAdService.incrementClicks(req.params.id)
        res.json(ad)
    } catch (error: any) {
        res.status(500).json({ message: error.message })
    }
}
