import dotenv from 'dotenv';
import path from 'path';
// @ts-ignore
import Yournotify from 'yournotify-node-sdk';

const envPath = path.resolve(__dirname, '../.env');
dotenv.config({ path: envPath });

async function probeSDK() {
    console.log('Testing YourNotify SDK...');
    const apiKey = process.env.YOURNOTIFY_API_KEY;
    const senderId = process.env.YOURNOTIFY_SENDER_ID;

    if (!apiKey || !senderId) {
        console.error('Missing credentials');
        return;
    }

    const client = new Yournotify(apiKey);

    try {
        console.log('Sending SMS via SDK...');
        // sendSMS(name, from, text, status, to)
        // Trying status: "active" as a guess, or maybe it's boolean?
        // Let's try "true" (as boolean) or "sent".
        // The SDK source passes it directly.

        // Trial 1: status = true
        const response = await client.sendSMS(
            "OTP Test", // name
            senderId,   // from
            "Your OTP is 123456", // text
            true,       // status ??
            ['+2348138639325'] // to (array)
        );

        console.log('Response (status=true):', response);

    } catch (error: any) {
        console.error('Error:', error);
    }
}

probeSDK();
