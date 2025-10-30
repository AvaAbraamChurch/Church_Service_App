const admin = require('firebase-admin');

// The emulators:exec command will set FIRESTORE_EMULATOR_HOST
// and other emulator-related environment variables so admin.app will
// connect to the local emulator when admin.initializeApp() is called
// without credentials in the emulator environment.

admin.initializeApp();
const db = admin.firestore();

async function main() {
  const docRef = await db.collection('messages').add({
    senderId: 'testSender',
    receiverId: 'testReceiver',
    text: 'Hello from emulator test',
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log('Test message written to:', docRef.id);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});

