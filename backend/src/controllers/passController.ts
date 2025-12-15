import { Request, Response } from 'express'
import { PassService } from '../services/passService'
import { AuthRequest } from '../middleware/auth'

export const generatePass = async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user!.userId
        const pass = await PassService.generatePass(userId, req.body)
        res.status(201).json(pass)
    } catch (e: any) {
        res.status(400).json({ message: e.message })
    }
}

export const getMyPasses = async (req: AuthRequest, res: Response) => {
    try {
        const passes = await PassService.getMyPasses(req.user!.userId)
        res.json(passes)
    } catch (e: any) {
        res.status(400).json({ message: e.message })
    }
}

export const validatePass = async (req: AuthRequest, res: Response) => {
    try {
        const { code, estateId } = req.body // Security usually scans and sends code + their estateId
        const result = await PassService.validateCode(code, estateId || req.user!.estateId)

        if (!result.success) return res.status(400).json(result)
        res.json(result)
    } catch (e: any) {
        res.status(400).json({ message: e.message })
    }
}

export const entryPass = async (req: Request, res: Response) => {
    try {
        const pass = await PassService.processEntry(req.params.id)
        res.json(pass)
    } catch (e: any) {
        res.status(400).json({ message: e.message })
    }
}

export const exitPass = async (req: Request, res: Response) => {
    try {
        const pass = await PassService.processExit(req.params.id)
        res.json(pass)
    } catch (e: any) {
        res.status(400).json({ message: e.message })
    }
}

export const cancelPass = async (req: AuthRequest, res: Response) => {
    try {
        const pass = await PassService.cancelPass(req.params.id, req.user!.userId)
        res.json(pass)
    } catch (e: any) {
        res.status(400).json({ message: e.message })
    }
}
