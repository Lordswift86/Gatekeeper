import dotenv from 'dotenv';
import path from 'path';

const envPath = path.resolve(__dirname, '../.env');
dotenv.config({ path: envPath });

async function probe() {
    console.log('Probing https://api.yournotify.com/campaigns/sms ...');

    // Derived from SDK source
    const url = 'https://api.yournotify.com/campaigns/sms';

    // Tests with different 'status' values
    const testCases = [true, "active", "sent", "draft"];

    for (const statusVal of testCases) {
        try {
            console.log(`\nTesting status: ${JSON.stringify(statusVal)}`);
            const response = await fetch(url, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${process.env.YOURNOTIFY_API_KEY}`
                },
                body: JSON.stringify({
                    name: "OTP Test Probe",
                    from: process.env.YOURNOTIFY_SENDER_ID, // "Kitaniz"
                    text: "Your OTP is 123456",
                    status: statusVal,
                    channel: "sms",
                    lists: ['+2348138639325']
                })
            });

            console.log(`Status: ${response.status}`);
            const text = await response.text();
            console.log('Response:', text);

            if (response.ok) {
                console.log('✅ SUCCESS!');
                break;
            }
        } catch (error: any) {
            console.log(`Error:`, error.message);
        }
    }
}

probe();
