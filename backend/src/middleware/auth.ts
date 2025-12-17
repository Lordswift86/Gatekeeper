import { Request, Response, NextFunction } from 'express'
import jwt from 'jsonwebtoken'
import { ApiError } from './errorHandler'



export interface AuthRequest extends Request {
    user?: {
        userId: string
        role: string
        estateId: string | null
    }
}

// Token authentication middleware
export const authenticateToken = (req: AuthRequest, res: Response, next: NextFunction) => {
    const authHeader = req.headers['authorization']
    const token = authHeader && authHeader.split(' ')[1]

    if (!token) {
        return next(ApiError.unauthorized('Access token required'))
    }

    const secret = process.env.JWT_SECRET || 'secret'

    jwt.verify(token, secret, (err: any, user: any) => {
        if (err) {
            console.error('[AUTH] JWT Verification Error:', {
                name: err.name,
                message: err.message,
                token: token.substring(0, 20) + '...'
            });
            if (err.name === 'TokenExpiredError') {
                return next(ApiError.unauthorized('Token has expired'))
            }
            return next(ApiError.forbidden('Invalid token'))
        }
        console.log('[AUTH] Token verified successfully:', {
            userId: user.userId,
            role: user.role,
            estateId: user.estateId
        });
        req.user = user
        next()
    })
}

// Role-based authorization middleware factory
export const requireRole = (...allowedRoles: string[]) => {
    return (req: AuthRequest, res: Response, next: NextFunction) => {
        if (!req.user) {
            return next(ApiError.unauthorized('Authentication required'))
        }

        if (!allowedRoles.includes(req.user.role)) {
            return next(ApiError.forbidden(`Access denied. Required role: ${allowedRoles.join(' or ')}`))
        }

        next()
    }
}

// Check if user belongs to the same estate
export const requireSameEstate = (req: AuthRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
        return next(ApiError.unauthorized('Authentication required'))
    }

    const estateId = req.params.estateId || req.body.estateId

    // Super admins can access any estate
    if (req.user.role === 'SUPER_ADMIN') {
        return next()
    }

    if (req.user.estateId !== estateId) {
        return next(ApiError.forbidden('Access denied. You can only access your own estate.'))
    }

    next()
}

// Check if user is approved
export const requireApproved = (req: AuthRequest, res: Response, next: NextFunction) => {
    // This would need to check the database - for now just pass through
    // In production, you'd cache user approval status or include it in the token
    next()
}

// Convenience role checks
export const requireAdmin = requireRole('SUPER_ADMIN', 'ESTATE_ADMIN')
export const requireSuperAdmin = requireRole('SUPER_ADMIN')
export const requireEstateAdmin = requireRole('ESTATE_ADMIN')
export const requireSecurity = requireRole('SECURITY')
export const requireResident = requireRole('RESIDENT')
