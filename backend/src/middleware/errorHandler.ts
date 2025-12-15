import { Request, Response, NextFunction } from 'express'

interface AppError extends Error {
    statusCode?: number
    code?: string
    details?: any
}

// Error response interface
interface ErrorResponse {
    error: string
    message: string
    code?: string
    details?: any
    stack?: string
}

// Global error handler
export const errorHandler = (
    err: AppError,
    req: Request,
    res: Response,
    next: NextFunction
) => {
    const statusCode = err.statusCode || 500
    const isProduction = process.env.NODE_ENV === 'production'

    const response: ErrorResponse = {
        error: statusCode >= 500 ? 'Internal Server Error' : 'Request Error',
        message: isProduction && statusCode >= 500
            ? 'An unexpected error occurred'
            : err.message,
        code: err.code
    }

    // Include stack trace in development
    if (!isProduction && err.stack) {
        response.stack = err.stack
    }

    // Include details if provided (e.g., validation errors)
    if (err.details) {
        response.details = err.details
    }

    // Log error (in production, use proper logging service)
    console.error(`[${new Date().toISOString()}] ${statusCode} - ${err.message}`, {
        path: req.path,
        method: req.method,
        stack: err.stack
    })

    res.status(statusCode).json(response)
}

// Custom error class
export class ApiError extends Error {
    statusCode: number
    code?: string
    details?: any

    constructor(message: string, statusCode: number = 500, code?: string, details?: any) {
        super(message)
        this.statusCode = statusCode
        this.code = code
        this.details = details
        Object.setPrototypeOf(this, ApiError.prototype)
    }

    static badRequest(message: string, details?: any) {
        return new ApiError(message, 400, 'BAD_REQUEST', details)
    }

    static unauthorized(message: string = 'Unauthorized') {
        return new ApiError(message, 401, 'UNAUTHORIZED')
    }

    static forbidden(message: string = 'Forbidden') {
        return new ApiError(message, 403, 'FORBIDDEN')
    }

    static notFound(message: string = 'Resource not found') {
        return new ApiError(message, 404, 'NOT_FOUND')
    }

    static conflict(message: string) {
        return new ApiError(message, 409, 'CONFLICT')
    }

    static tooManyRequests(message: string = 'Too many requests') {
        return new ApiError(message, 429, 'RATE_LIMIT_EXCEEDED')
    }

    static internal(message: string = 'Internal server error') {
        return new ApiError(message, 500, 'INTERNAL_ERROR')
    }
}

// Async handler wrapper to catch async errors
export const asyncHandler = (fn: Function) => (
    req: Request,
    res: Response,
    next: NextFunction
) => {
    Promise.resolve(fn(req, res, next)).catch(next)
}

// 404 handler for unknown routes
export const notFoundHandler = (req: Request, res: Response) => {
    res.status(404).json({
        error: 'Not Found',
        message: `Route ${req.method} ${req.path} not found`,
        code: 'ROUTE_NOT_FOUND'
    })
}
