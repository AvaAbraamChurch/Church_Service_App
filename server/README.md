# Notification server examples

This folder contains two examples for sending Firebase Cloud Messaging (FCM) notifications from server-side code.

1) Standalone Node.js script (for local testing)
2) Firebase Cloud Function (already present in `functions/index.js`) — `sendTestNotification` HTTP function

## 1) Standalone Node.js script

Files:
- `send_notification.js`
- `package.json`

How to use:
1. Copy your Firebase service account JSON into `server/serviceAccountKey.json` (this file must be kept secret).
2. From the `server` folder run:

```bash
npm install
```

3. Send to a token:

```bash
node send_notification.js --token "<DEVICE_FCM_TOKEN>"
```

4. Send to a topic:

```bash
node send_notification.js --topic "news"
```

The script uses the Firebase Admin SDK to send a simple notification with a small data payload.

## 2) Firebase Cloud Function HTTP endpoint

A Cloud Function `sendTestNotification` was added to `functions/index.js`. It accepts either a `token` or `topic` and sends a test notification.

Security: The function expects an API key to be set in the `TEST_NOTIFICATION_KEY` environment variable for your functions runtime. Provide the key in the `x-api-key` header or `key` query parameter.

Example (after deploying functions):

```bash
curl -X POST "https://<your-region>-<your-project>.cloudfunctions.net/sendTestNotification" \
  -H "Content-Type: application/json" \
  -H "x-api-key: <YOUR_TEST_NOTIFICATION_KEY>" \
  -d '{"token":"<FCM_TOKEN>", "title":"Test", "body":"Hello from Cloud Function"}'
```

Or to send to topic `news`:

```bash
curl "https://<your-region>-<your-project>.cloudfunctions.net/sendTestNotification?key=<YOUR_TEST_NOTIFICATION_KEY>&topic=news&title=TopicTest&body=Hello"
```

Remember to set `TEST_NOTIFICATION_KEY` in your Firebase Functions environment before deploying:

```bash
firebase functions:config:set notifications.test_key="your-secret-key"
# or use the `gcloud` tool or Firebase Console to set env vars for functions
```

Then deploy:

```bash
cd functions
npm run deploy
```

(Adjust commands to your environment and CI setup.)

Security note: Keep the service account and API keys secret. For production, use IAM and more robust authentication/authorization for management endpoints.

