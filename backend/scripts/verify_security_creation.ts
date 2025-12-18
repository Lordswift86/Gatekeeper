
import { EstateService } from '../src/services/estateService';
import { AuthService } from '../src/services/authService';
import prisma from '../src/config/db';

async function main() {
    console.log('--- Starting Verification ---');

    // 1. Setup Data
    const estateName = 'Test Estate ' + Date.now();
    const adminPhone = '+2348000000000';
    const securityPhone = '08111111111'; // Raw format to test formatting
    const securityPassword = 'password123';

    try {
        // Create Estate directly
        const estate = await prisma.estate.create({
            data: {
                name: estateName,
                code: 'TEST' + Math.floor(Math.random() * 1000),
                subscriptionTier: 'FREE',
                status: 'ACTIVE'
            }
        });
        console.log('1. Created Estate:', estate.id);

        // 2. Call updateEstate with security credentials
        console.log('2. Updating Estate with Security Credentials...');
        await EstateService.updateEstate(estate.id, {
            securityPhone: securityPhone,
            securityPassword: securityPassword
        });
        console.log('   Update completed.');

        // 3. Verify User Creation
        const formattedSecurityPhone = '+234' + securityPhone.substring(1); // Expected format
        const securityUser = await prisma.user.findUnique({
            where: { phone: formattedSecurityPhone }
        });

        if (!securityUser) {
            console.error('❌ FAILED: Security user was NOT created.');
            process.exit(1);
        }
        console.log('3. Verified Security User exists:', securityUser.id, securityUser.phone);

        // 4. Test Login
        console.log('4. Testing Login...');
        try {
            const loginResult = await AuthService.loginWithPassword(securityPhone, securityPassword);
            console.log('✅ SUCCESS: Login successful!', loginResult.user.role);
        } catch (error) {
            console.error('❌ FAILED: Login failed:', error);
            process.exit(1);
        }

    } catch (error) {
        console.error('❌ UNEXPECTED ERROR:', error);
    } finally {
        await prisma.$disconnect();
    }
}

main();
