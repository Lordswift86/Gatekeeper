import { Request, Response } from 'express'
import { AuthService } from '../services/authService'

export const login = async (req: Request, res: Response) => {
    try {
        const { email, phone, password } = req.body

        // Allow 'email' OR 'phone' field from frontend to act as identifier
        const identifier = email || phone

        if (!identifier || !password) {
            return res.status(400).json({ message: 'Email/Phone and Password are required' })
        }

        const result = await AuthService.loginWithPassword(identifier, password)
        res.json(result)
    } catch (error: any) {
        res.status(401).json({ message: error.message || 'Login failed' })
    }
}

export const register = async (req: Request, res: Response) => {
    try {
        const result = await AuthService.register(req.body)
        res.status(201).json(result)
    } catch (error: any) {
        res.status(400).json({ message: error.message || 'Registration failed' })
    }
}

export const registerEstateAdmin = async (req: Request, res: Response) => {
    try {
        const result = await AuthService.registerEstateAdmin(req.body)
        res.status(201).json(result)
    } catch (error: any) {
        res.status(400).json({ message: error.message || 'Estate admin registration failed' })
    }
}
