-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_User" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "email" TEXT NOT NULL,
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
INSERT INTO "new_User" ("createdAt", "email", "estateId", "id", "isApproved", "name", "password", "photoUrl", "role", "unitNumber", "updatedAt") SELECT "createdAt", "email", "estateId", "id", "isApproved", "name", "password", "photoUrl", "role", "unitNumber", "updatedAt" FROM "User";
DROP TABLE "User";
ALTER TABLE "new_User" RENAME TO "User";
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
