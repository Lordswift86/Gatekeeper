/*
  Warnings:

  - You are about to drop the column `content` on the `GlobalAd` table. All the data in the column will be lost.
  - You are about to drop the column `title` on the `GlobalAd` table. All the data in the column will be lost.

*/
-- CreateTable
CREATE TABLE "OtpVerification" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "phone" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "purpose" TEXT NOT NULL,
    "expiresAt" DATETIME NOT NULL,
    "verified" BOOLEAN NOT NULL DEFAULT false,
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_GlobalAd" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "imageUrl" TEXT,
    "targetUrl" TEXT,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "startDate" DATETIME,
    "endDate" DATETIME,
    "impressions" INTEGER NOT NULL DEFAULT 0,
    "clicks" INTEGER NOT NULL DEFAULT 0,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO "new_GlobalAd" ("createdAt", "id", "imageUrl", "impressions", "isActive") SELECT "createdAt", "id", "imageUrl", "impressions", "isActive" FROM "GlobalAd";
DROP TABLE "GlobalAd";
ALTER TABLE "new_GlobalAd" RENAME TO "GlobalAd";
CREATE TABLE "new_User" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "phone" TEXT,
    "phoneVerified" BOOLEAN NOT NULL DEFAULT false,
    "email" TEXT,
    "password" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "role" TEXT NOT NULL,
    "estateId" TEXT,
    "unitNumber" TEXT,
    "photoUrl" TEXT,
    "isApproved" BOOLEAN NOT NULL DEFAULT false,
    "primaryUserId" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "User_primaryUserId_fkey" FOREIGN KEY ("primaryUserId") REFERENCES "User" ("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "User_estateId_fkey" FOREIGN KEY ("estateId") REFERENCES "Estate" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);
INSERT INTO "new_User" ("createdAt", "email", "estateId", "id", "isApproved", "name", "password", "photoUrl", "primaryUserId", "role", "unitNumber", "updatedAt") SELECT "createdAt", "email", "estateId", "id", "isApproved", "name", "password", "photoUrl", "primaryUserId", "role", "unitNumber", "updatedAt" FROM "User";
DROP TABLE "User";
ALTER TABLE "new_User" RENAME TO "User";
CREATE UNIQUE INDEX "User_phone_key" ON "User"("phone");
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
