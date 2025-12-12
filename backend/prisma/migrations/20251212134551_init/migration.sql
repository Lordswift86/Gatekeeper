-- CreateTable
CREATE TABLE "Estate" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "name" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "subscriptionTier" TEXT NOT NULL DEFAULT 'FREE',
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "email" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "role" TEXT NOT NULL,
    "estateId" TEXT,
    "unitNumber" TEXT,
    "isApproved" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "User_estateId_fkey" FOREIGN KEY ("estateId") REFERENCES "Estate" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "GuestPass" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "code" TEXT NOT NULL,
    "hostId" TEXT NOT NULL,
    "guestName" TEXT NOT NULL,
    "hostUnit" TEXT,
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "type" TEXT NOT NULL DEFAULT 'ONE_TIME',
    "validFrom" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "validUntil" DATETIME NOT NULL,
    "entryTime" DATETIME,
    "exitTime" DATETIME,
    "exitInstruction" TEXT,
    "recurringDays" TEXT,
    "recurringTimeStart" TEXT,
    "recurringTimeEnd" TEXT,
    "plateNumber" TEXT,
    "deliveryCompany" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "GuestPass_hostId_fkey" FOREIGN KEY ("hostId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Announcement" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "estateId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Announcement_estateId_fkey" FOREIGN KEY ("estateId") REFERENCES "Estate" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "LogEntry" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "estateId" TEXT NOT NULL,
    "guestName" TEXT NOT NULL,
    "destination" TEXT NOT NULL,
    "entryTime" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "exitTime" DATETIME,
    "type" TEXT NOT NULL,
    "notes" TEXT,
    CONSTRAINT "LogEntry_estateId_fkey" FOREIGN KEY ("estateId") REFERENCES "Estate" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Bill" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "estateId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "amount" REAL NOT NULL,
    "dueDate" DATETIME NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'UNPAID',
    "paidAt" DATETIME,
    "description" TEXT NOT NULL,
    CONSTRAINT "Bill_estateId_fkey" FOREIGN KEY ("estateId") REFERENCES "Estate" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Bill_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "IntercomSession" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "estateId" TEXT NOT NULL,
    "residentId" TEXT NOT NULL,
    "securityId" TEXT,
    "initiator" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'RINGING',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "endedAt" DATETIME,
    CONSTRAINT "IntercomSession_estateId_fkey" FOREIGN KEY ("estateId") REFERENCES "Estate" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "IntercomSession_residentId_fkey" FOREIGN KEY ("residentId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "IntercomSession_securityId_fkey" FOREIGN KEY ("securityId") REFERENCES "User" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "ChatMessage" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "fromId" TEXT NOT NULL,
    "toId" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "read" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "ChatMessage_fromId_fkey" FOREIGN KEY ("fromId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "ChatMessage_toId_fkey" FOREIGN KEY ("toId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "EmergencyAlert" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "estateId" TEXT NOT NULL,
    "residentId" TEXT NOT NULL,
    "unitNumber" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "EmergencyAlert_estateId_fkey" FOREIGN KEY ("estateId") REFERENCES "Estate" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "GlobalAd" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "title" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "imageUrl" TEXT,
    "impressions" INTEGER NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateTable
CREATE TABLE "SystemLog" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "action" TEXT NOT NULL,
    "actor" TEXT NOT NULL,
    "details" TEXT NOT NULL,
    "severity" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateIndex
CREATE UNIQUE INDEX "Estate_code_key" ON "Estate"("code");

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "GuestPass_code_key" ON "GuestPass"("code");
