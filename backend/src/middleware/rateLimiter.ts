import rateLimit from 'express-rate-limit'

// General API rate limiter
export const apiLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 1000, // 1000 requests per window (Relaxed for testing)
    standardHeaders: true,
    legacyHeaders: false,
    message: {
        error: 'Too many requests',
        message: 'You have exceeded the rate limit. Please try again later.',
        retryAfter: '15 minutes'
    }
})

// Stricter limiter for auth endpoints
export const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // 100 login attempts per window (Relaxed for testing)
    standardHeaders: true,
    legacyHeaders: false,
    message: {
        error: 'Too many login attempts',
        message: 'Too many login attempts. Please try again in 15 minutes.',
        retryAfter: '15 minutes'
    },
    skipSuccessfulRequests: true // Don't count successful logins
})

// Very strict for password reset, registration, etc.
export const sensitiveOpLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 hour
    max: 3, // 3 attempts per hour
    standardHeaders: true,
    legacyHeaders: false,
    message: {
        error: 'Rate limit exceeded',
        message: 'Too many attempts. Please try again in an hour.',
        retryAfter: '1 hour'
    }
})
