// Simple Node.js script to send a test FCM message using Firebase Admin SDK
// Usage:
// 1) Place your service account JSON at ./serviceAccountKey.json
// 2) Install deps: npm install
// 3) Send to token: node send_notification.js --token "<FCM_TOKEN>"
//    or: npm run send:token -- "<FCM_TOKEN>"
// 4) Send to topic: node send_notification.js --topic "news"

const admin = require('firebase-admin');
const argv = require('minimist')(process.argv.slice(2));

const serviceAccountPath = './serviceAccountKey.json';

try {
  const serviceAccount = require(serviceAccountPath);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
} catch (e) {
  console.error(`Failed to load service account from ${serviceAccountPath}. Make sure the file exists and is valid.`);
  console.error(e);
  process.exit(1);
}

async function sendToToken(token) {
  const message = {
    token: token,
    notification: {
      title: 'Test Notification',
      body: 'This is a test message from server/send_notification.js'
    },
    data: {
      source: 'server-script',
      timestamp: String(Date.now())
    }
  };

  try {
    const res = await admin.messaging().send(message);
    console.log('Successfully sent message:', res);
  } catch (err) {
    console.error('Error sending message:', err);
  }
}

async function sendToTopic(topic) {
  const message = {
    topic: topic,
    notification: {
      title: 'Topic Test',
      body: `This is a test message to topic ${topic}`
    },
    data: {
      source: 'server-script',
      timestamp: String(Date.now())
    }
  };

  try {
    const res = await admin.messaging().send(message);
    console.log('Successfully sent topic message:', res);
  } catch (err) {
    console.error('Error sending topic message:', err);
  }
}

(async () => {
  if (argv.token) {
    await sendToToken(argv.token);
    return;
  }
  if (argv.topic) {
    await sendToTopic(argv.topic);
    return;
  }

  console.log('Usage: node send_notification.js --token "<FCM_TOKEN>"');
  console.log('   or: node send_notification.js --topic "<TOPIC_NAME>"');
})();

