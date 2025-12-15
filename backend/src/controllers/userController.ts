import { Request, Response } from 'express'
import { UserService } from '../services/userService'

export const getProfile = async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user.userId
        const user = await UserService.getProfile(userId)
        res.json(user)
    } catch (error: any) {
        res.status(500).json({ message: error.message })
    }
}

export const updateProfile = async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user.userId
        const user = await UserService.updateProfile(userId, req.body)
        res.json(user)
    } catch (error: any) {
        res.status(500).json({ message: error.message })
    }
}

export const getPendingUsers = async (req: Request, res: Response) => {
    try {
        const estateId = (req as any).user.estateId
        const users = await UserService.getPendingUsers(estateId)
        res.json(users)
    } catch (error: any) {
        res.status(500).json({ message: error.message })
    }
}

export const approveUser = async (req: Request, res: Response) => {
    try {
        const { id } = req.params
        await UserService.approveUser(id)
        res.json({ message: 'User approved' })
    } catch (error: any) {
        res.status(500).json({ message: error.message })
    }
}

export const getAllUsers = async (req: Request, res: Response) => {
    try {
        const users = await UserService.getAllUsers()
        res.json(users)
    } catch (error: any) {
        res.status(500).json({ message: error.message })
    }
}

export const getAllResidents = async (req: Request, res: Response) => {
    try {
        const estateId = (req as any).user.estateId
        if (!estateId) throw new Error('No estate associated')

        const residents = await UserService.getResidentsByEstate(estateId)
        res.json(residents)
    } catch (error: any) {
        res.status(500).json({ message: error.message })
    }
}

export const createSecurityAccount = async (req: Request, res: Response) => {
    try {
        const estateId = (req as any).user.estateId
        if (!estateId) throw new Error('No estate associated with admin')

        const { name, email, password } = req.body
        if (!name || !email || !password) {
            return res.status(400).json({ message: 'Name, email, and password are required' })
        }

        const user = await UserService.createSecurityAccount({
            name,
            email,
            password,
            estateId
        })

        res.status(201).json({ user, message: 'Security account created successfully' })
    } catch (error: any) {
        res.status(400).json({ message: error.message })
    }
}
