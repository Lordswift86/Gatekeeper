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

export const refreshToken = async (req: Request, res: Response) => {
    try {
        const { refreshToken } = req.body
        const result = await AuthService.refreshAccessToken(refreshToken)
        res.json(result)
    } catch (error: any) {
        res.status(403).json({ message: error.message || 'Token refresh failed' })
    }
}

export const logout = async (req: Request, res: Response) => {
    try {
        const { refreshToken } = req.body
        await AuthService.logout(refreshToken)
        res.json({ message: 'Logged out successfully' })
    } catch (error: any) {
        res.status(200).json({ message: 'Logged out successfully' }) // Always return success for logout
    }
}

export const resetPassword = async (req: Request, res: Response) => {
    try {
        const { phone, newPassword } = req.body

        if (!phone || !newPassword) {
            return res.status(400).json({ message: 'Phone and new password are required' })
        }

        if (newPassword.length < 6) {
            return res.status(400).json({ message: 'Password must be at least 6 characters' })
        }

        await AuthService.resetPassword(phone, newPassword)
        res.json({ message: 'Password reset successfully' })
    } catch (error: any) {
        res.status(400).json({ message: error.message || 'Password reset failed' })
    }
}
