
import swaggerJsdoc from 'swagger-jsdoc';

const options: swaggerJsdoc.Options = {
    definition: {
        openapi: '3.0.0',
        info: {
            title: 'Gatekeeper API',
            version: '1.0.0',
            description: 'API Documentation for the Gatekeeper Estate Management System',
        },
        servers: process.env.NODE_ENV === 'production'
            ? [
                {
                    url: 'https://kitaniz.cloud/api',
                    description: 'Production Server',
                },
            ]
            : [
                {
                    url: 'http://localhost:3000/api',
                    description: 'Local Development Server',
                },
                {
                    url: 'https://kitaniz.cloud/api',
                    description: 'Production Server',
                },
            ],
        components: {
            securitySchemes: {
                bearerAuth: {
                    type: 'http',
                    scheme: 'bearer',
                    bearerFormat: 'JWT',
                },
            },
        },
        security: [
            {
                bearerAuth: [],
            },
        ],
    },
    apis: ['./src/routes/*.ts'], // Path to the API docs
};

const swaggerSpec = swaggerJsdoc(options);

export default swaggerSpec;
