import { Request, Response, NextFunction } from 'express'
import { z, ZodSchema } from 'zod'
import { ApiError } from './errorHandler'

// Validation middleware factory
// Updated schema to include phone validation
export const validate = <T>(schema: ZodSchema<T>, source: 'body' | 'query' | 'params' = 'body') => {
    return (req: Request, res: Response, next: NextFunction) => {
        try {
            const data = source === 'body' ? req.body : source === 'query' ? req.query : req.params
            const result = schema.safeParse(data)

            if (!result.success) {
                const errors = result.error.issues.map((issue) => ({
                    field: issue.path.join('.'),
                    message: issue.message
                }))

                throw ApiError.badRequest('Validation failed', errors)
            }

            // Replace body with parsed data (includes defaults and transformations)
            if (source === 'body') {
                req.body = result.data
            }

            next()
        } catch (error) {
            next(error)
        }
    }
}

// ============ Common Schemas ============

export const schemas = {
    // Auth schemas
    login: z.object({
        identifier: z.string().optional(), // Web dashboard sends this
        phone: z.string().optional(),      // Mobile apps send this
        email: z.string().optional(),      // Some may send this
        password: z.string().min(1, 'Password is required')
    }).refine(data => data.identifier || data.phone || data.email, {
        message: 'Email, phone, or identifier is required'
    }),

    register: z.object({
        name: z.string().min(2, 'Name must be at least 2 characters'),
        phone: z.string().min(10, 'Phone number is required'),
        email: z.string().email('Invalid email format').optional(),
        password: z.string().min(8, 'Password must be at least 8 characters'),
        role: z.enum(['RESIDENT', 'SECURITY', 'ESTATE_ADMIN']),
        estateCode: z.string().min(1, 'Estate code is required'),
        unitNumber: z.string().optional()
    }),

    registerEstateAdmin: z.object({
        user: z.object({
            name: z.string().min(2, 'Name must be at least 2 characters'),
            phone: z.string().min(10, 'Phone number is required'),
            password: z.string().min(6, 'Password must be at least 6 characters'),
            email: z.string().email('Invalid email format').optional()
        }),
        estate: z.object({
            name: z.string().min(2, 'Estate name must be at least 2 characters'),
            address: z.string().optional(),
            description: z.string().optional()
        })
    }),

    // Pass schemas
    createPass: z.object({
        guestName: z.string().min(1, 'Guest name is required'),
        type: z.enum(['ONE_TIME', 'RECURRING', 'DELIVERY']).default('ONE_TIME'),
        exitInstruction: z.string().optional(),
        deliveryCompany: z.string().optional(),
        recurringDays: z.array(z.string()).optional(),
        recurringTimeStart: z.string().optional(),
        recurringTimeEnd: z.string().optional()
    }),

    // ID param validation
    idParam: z.object({
        id: z.string().uuid('Invalid ID format')
    }),

    // Pagination
    pagination: z.object({
        page: z.coerce.number().min(1).default(1),
        limit: z.coerce.number().min(1).max(100).default(20)
    }),

    // Bill schemas
    createBill: z.object({
        userId: z.string().uuid('Invalid user ID'),
        type: z.enum(['SERVICE_CHARGE', 'POWER', 'WASTE', 'WATER']),
        amount: z.number().positive('Amount must be positive'),
        dueDate: z.string().or(z.date()),
        description: z.string().min(1, 'Description is required')
    }),

    // Announcement schemas
    createAnnouncement: z.object({
        title: z.string().min(1, 'Title is required').max(200),
        content: z.string().min(1, 'Content is required').max(2000)
    }),

    // Estate schemas
    createEstate: z.object({
        name: z.string().min(2, 'Estate name must be at least 2 characters'),
        code: z.string().min(4, 'Estate code must be at least 4 characters').max(20)
    }),

    updateProfile: z.object({
        name: z.string().min(2).optional(),
        unitNumber: z.string().optional()
    })
}
