# Gatekeeper Backend API

A robust Node.js backend for the Gatekeeper Estate Management System.

## Tech Stack

- **Runtime**: Node.js with TypeScript
- **Framework**: Express.js
- **Database**: Prisma ORM (SQLite/PostgreSQL)
- **Authentication**: JWT
- **Real-time**: Socket.io

## Getting Started

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment

Copy `.env.example` to `.env` and update values:

```bash
cp .env.example .env
```

### 3. Initialize Database

```bash
# Generate Prisma Client
npx prisma generate

# Run migrations (creates database)
npx prisma migrate dev --name init

# Seed database with sample data
npx prisma db seed
```

### 4. Run Development Server

```bash
npm run dev
```

Server will start on `http://localhost:3000`

## API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration

### Estates
- `GET /api/estates` - List all estates
- `GET /api/estates/:id` - Get estate details
- `POST /api/estates` - Create estate (Admin only)
- `PUT /api/estates/:id/status` - Toggle estate status

### Passes
- `POST /api/passes/generate` - Generate guest pass
- `GET /api/passes/my-passes` - Get my passes
- `POST /api/passes/validate` - Validate pass code
- `POST /api/passes/:id/entry` - Process entry
- `POST /api/passes/:id/exit` - Process exit

### Users
- `GET /api/users/profile` - Get user profile
- `PUT /api/users/profile` - Update profile
- `GET /api/users/pending` - Get pending users (Admin)
- `POST /api/users/:id/approve` - Approve user (Admin)

### Bills
- `GET /api/bills/my` - Get my bills
- `GET /api/bills/estate` - Get estate bills (Admin)
- `POST /api/bills` - Create bill (Admin)
- `POST /api/bills/:id/pay` - Pay bill

### Security
- `GET /api/security/logs` - Get estate logs
- `POST /api/security/logs` - Add manual log entry
- `GET /api/security/announcements` - Get announcements
- `POST /api/security/announcements` - Create announcement (Admin)

## WebSocket Events

### Client → Server
- `join-estate` - Join estate room
- `initiate-call` - Start intercom call
- `answer-call` - Answer call
- `end-call` - End call
- `send-message` - Send chat message
- `send-sos` - Trigger emergency alert

### Server → Client
- `incoming-call` - New call notification
- `call-answered` - Call answered
- `call-ended` - Call ended
- `new-message` - New chat message
- `emergency-alert` - Emergency SOS alert

## Authentication

All protected routes require a JWT token in the Authorization header:

```
Authorization: Bearer <token>
```

## Database Schema

See `prisma/schema.prisma` for complete data model.

## Scripts

- `npm run dev` - Development server with auto-reload
- `npm run build` - Build for production
- `npm start` - Run production build
- `npx prisma studio` - Open database GUI
- `npx prisma db seed` - Seed database

## Project Structure

```
backend/
├── src/
│   ├── config/       # Configuration (DB, env)
│   ├── controllers/  # Request handlers
│   ├── middleware/   # Auth, logging
│   ├── routes/       # API route definitions
│   ├── services/     # Business logic
│   ├── app.ts        # Express app
│   └── socket.ts     # Socket.io setup
├── prisma/
│   ├── schema.prisma # Database schema
│   └── seed.ts       # Seed data
├── .env              # Environment variables
└── package.json
```

## Default Users (After Seeding)

All users have password: `password123`

- **Super Admin**: `admin@gatekeeper.com`
- **Estate Admin**: `alice@sunset.com`
- **Resident**: `bob@sunset.com`
- **Security**: `sam@sunset.com`

## Next Steps

1. Configure PostgreSQL for production (update `DATABASE_URL`)
2. Implement proper CORS configuration
3. Add rate limiting
4. Set up logging (e.g., Winston)
5. Add comprehensive error handling
6. Write unit/integration tests
