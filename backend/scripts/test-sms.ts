import dotenv from 'dotenv';
import path from 'path';

// Load env vars from backend root
const envPath = path.resolve(__dirname, '../.env');
console.log(`Loading .env from ${envPath}`);
dotenv.config({ path: envPath });

// Import service after env vars are loaded
import { SMSService } from '../src/services/smsService';

async function main() {
    const args = process.argv.slice(2);
    if (args.length === 0) {
        console.error('Please provide a phone number as an argument.');
        console.error('Usage: npx ts-node scripts/test-sms.ts <phone_number>');
        process.exit(1);
    }

    const phone = args[0];
    console.log(`\nTesting SMS for ${phone}...`);
    console.log(`Environment Check:`);
    console.log(`- API Key Present: ${!!process.env.AFRICASTALKING_API_KEY}`);
    console.log(`- Username: ${process.env.AFRICASTALKING_USERNAME}`);
    console.log(`- Sender ID: ${process.env.AFRICASTALKING_SENDER_ID}`);

    try {
        console.log('\nSending message...');
        const success = await SMSService.sendSMS(phone, 'This is a test message from Gatekeeper via SMS Broadcast.');

        if (success) {
            console.log('\n✅ SMS sent successfully!');
        } else {
            console.error('\n❌ Failed to send SMS (Service returned false).');
        }
    } catch (error) {
        console.error('\n❌ Error sending SMS:', error);
    }
}

main().catch(console.error);
