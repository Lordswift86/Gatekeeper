import { Request, Response } from 'express'
import { AuthService } from '../services/authService'

export const login = async (req: Request, res: Response) => {
    try {
        const { email, password } = req.body

        // Support both proper login and the "mock" style email-only login for testing if needed,
        // but preferably enforce password.
        // For now, if no password provided, maybe fail? 
        // Let's implement proper password login.

        if (!password) {
            // Fallback for mock compatibility if strictly needed? 
            // No, backend should be secure.
            return res.status(400).json({ message: 'Password is required' })
        }

        const result = await AuthService.loginWithPassword(email, password)
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
