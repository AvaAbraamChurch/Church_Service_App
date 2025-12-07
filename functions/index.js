const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Cloud Function to update Remote Config
 * Only callable by authenticated admin users
 */
exports.updateRemoteConfig = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to call this function.'
    );
  }

  try {
    // Verify user is admin by checking custom claims or Firestore
    const uid = context.auth.uid;
    const userDoc = await admin.firestore().collection('users').doc(uid).get();

    if (!userDoc.exists || userDoc.data().role !== 'Priest') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only priests can update remote config.'
      );
    }

    // Get the Remote Config template
    const template = await admin.remoteConfig().getTemplate();

    // Update the parameters based on provided data
    const updates = data.updates || {};

    // Theme configuration keys
    const validKeys = [
      'theme_primary_color',
      'theme_secondary_color',
      'theme_scaffold_background_color',
      'theme_scaffold_background_image',
      'theme_appbar_background_color',
      'theme_is_dark_mode',
      'theme_font_family',
      'enable_custom_theme'
    ];

    // Update each parameter
    for (const [key, value] of Object.entries(updates)) {
      if (!validKeys.includes(key)) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          `Invalid configuration key: ${key}`
        );
      }

      // Determine the value type
      let defaultValue;
      if (typeof value === 'boolean') {
        defaultValue = { value: String(value) };
      } else if (typeof value === 'string') {
        defaultValue = { value: value };
      } else {
        defaultValue = { value: String(value) };
      }

      // Update or create the parameter
      template.parameters[key] = {
        defaultValue: defaultValue,
        description: `Updated by admin at ${new Date().toISOString()}`,
        valueType: 'STRING'
      };
    }

    // Validate and publish the template
    const validatedTemplate = await admin.remoteConfig().validateTemplate(template);
    await admin.remoteConfig().publishTemplate(validatedTemplate);

    // Log the update
    await admin.firestore().collection('config_updates').add({
      updatedBy: uid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      updates: updates,
      version: validatedTemplate.version
    });

    return {
      success: true,
      message: 'Remote Config updated successfully',
      version: validatedTemplate.version
    };

  } catch (error) {
    console.error('Error updating Remote Config:', error);

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      'Failed to update Remote Config: ' + error.message
    );
  }
});

/**
 * Cloud Function to get current Remote Config values
 * Only callable by authenticated admin users
 */
exports.getRemoteConfig = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to call this function.'
    );
  }

  try {
    // Verify user is admin
    const uid = context.auth.uid;
    const userDoc = await admin.firestore().collection('users').doc(uid).get();

    if (!userDoc.exists || userDoc.data().role !== 'Priest') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only priests can view remote config.'
      );
    }

    // Get the Remote Config template
    const template = await admin.remoteConfig().getTemplate();

    // Extract theme parameters
    const config = {};
    const themeKeys = [
      'theme_primary_color',
      'theme_secondary_color',
      'theme_scaffold_background_color',
      'theme_scaffold_background_image',
      'theme_appbar_background_color',
      'theme_is_dark_mode',
      'theme_font_family',
      'enable_custom_theme'
    ];

    for (const key of themeKeys) {
      if (template.parameters[key]) {
        config[key] = template.parameters[key].defaultValue.value;
      }
    }

    return {
      success: true,
      config: config,
      version: template.version
    };

  } catch (error) {
    console.error('Error getting Remote Config:', error);

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      'Failed to get Remote Config: ' + error.message
    );
  }
});

/**
 * Send push notification when a new message is created in Firestore
 * Expected messages documents structure:
 * {
 *   senderId: string,
 *   receiverId: string,
 *   text: string,
 *   timestamp: Timestamp,
 *   ...
 * }
 */
exports.sendMessageNotification = functions.firestore
  .document('messages/{messageId}')
  .onCreate(async (snap, context) => {
    try {
      const message = snap.data();
      if (!message) return null;

      const receiverId = message.receiverId;
      const senderId = message.senderId;
      const text = message.text || '';

      if (!receiverId) return null;

      const userRef = admin.firestore().collection('users').doc(receiverId);
      const userDoc = await userRef.get();
      if (!userDoc.exists) return null;

      const userData = userDoc.data() || {};

      // Support both array of tokens (fcmTokens) and legacy single token (fcmToken)
      let tokens = [];
      if (Array.isArray(userData.fcmTokens) && userData.fcmTokens.length > 0) {
        tokens = userData.fcmTokens;
      } else if (typeof userData.fcmToken === 'string' && userData.fcmToken.length > 0) {
        tokens = [userData.fcmToken];
      }

      if (tokens.length === 0) {
        console.log(`No FCM tokens for user ${receiverId}`);
        return null;
      }

      // Build notification payload
      const payload = {
        notification: {
          title: userData.displayName ? `${userData.displayName}` : 'New message',
          body: text || 'You have a new message',
        },
        data: {
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          senderId: senderId || '',
          messageId: context.params.messageId || '',
        },
      };

      // Send to multiple tokens
      const response = await admin.messaging().sendToDevice(tokens, payload);

      // Collect tokens that are invalid and remove them
      const tokensToRemove = [];
      if (response && response.results) {
        response.results.forEach((result, idx) => {
          const error = result.error;
          if (error) {
            console.error('Error sending to', tokens[idx], error);
            // If token is invalid or not registered, remove it from the DB
            if (
              error.code === 'messaging/invalid-registration-token' ||
              error.code === 'messaging/registration-token-not-registered'
            ) {
              tokensToRemove.push(tokens[idx]);
            }
          }
        });
      }

      // Remove invalid tokens from user document
      for (const tkn of tokensToRemove) {
        try {
          await userRef.update({ fcmTokens: admin.firestore.FieldValue.arrayRemove(tkn) });
        } catch (e) {
          console.warn('Failed to remove token from user doc', e);
        }
      }

      return null;
    } catch (error) {
      console.error('sendMessageNotification error:', error);
      return null;
    }
  });

/**
 * Scheduled function to check for birthdays and send notifications
 * Runs every day at 8:00 AM
 * Format: minute hour day month dayOfWeek
 */
exports.checkBirthdays = functions.pubsub
  .schedule('0 8 * * *')
  .timeZone('Africa/Cairo') // Adjust timezone as needed
  .onRun(async (context) => {
    try {
      const today = new Date();
      const currentMonth = today.getMonth() + 1; // JavaScript months are 0-indexed
      const currentDay = today.getDate();

      console.log(`Checking birthdays for ${currentDay}/${currentMonth}`);

      // Get all children (SS = Sunday School, CH = Child)
      const usersSnapshot = await admin
        .firestore()
        .collection('users')
        .where('userType', 'in', ['SS', 'CH'])
        .get();

      if (usersSnapshot.empty) {
        console.log('No children found in database');
        return null;
      }

      // Filter users with birthdays today
      const birthdayUsers = [];
      usersSnapshot.forEach((doc) => {
        const user = doc.data();
        const birthday = user.birthday;

        if (birthday) {
          let birthdayDate;
          // Handle Firestore Timestamp
          if (birthday.toDate) {
            birthdayDate = birthday.toDate();
          } else if (birthday instanceof Date) {
            birthdayDate = birthday;
          } else if (typeof birthday === 'string') {
            birthdayDate = new Date(birthday);
          }

          if (
            birthdayDate &&
            birthdayDate.getMonth() + 1 === currentMonth &&
            birthdayDate.getDate() === currentDay
          ) {
            const age = today.getFullYear() - birthdayDate.getFullYear();
            birthdayUsers.push({
              id: doc.id,
              name: user.fullName || user.name || 'Unknown',
              age: age,
            });
          }
        }
      });

      console.log(`Found ${birthdayUsers.length} birthdays today`);

      if (birthdayUsers.length === 0) {
        return null;
      }

      // Get all servants and priests to notify them
      const servantsSnapshot = await admin
        .firestore()
        .collection('users')
        .where('userType', 'in', ['SV', 'PR']) // SV = Servant, PR = Priest
        .get();

      if (servantsSnapshot.empty) {
        console.log('No servants/priests found to notify');
        return null;
      }

      // Collect all FCM tokens
      const tokens = [];
      servantsSnapshot.forEach((doc) => {
        const userData = doc.data();
        if (Array.isArray(userData.fcmTokens) && userData.fcmTokens.length > 0) {
          tokens.push(...userData.fcmTokens);
        } else if (typeof userData.fcmToken === 'string' && userData.fcmToken.length > 0) {
          tokens.push(userData.fcmToken);
        }
      });

      console.log(`Found ${tokens.length} tokens to send notifications to`);

      if (tokens.length === 0) {
        return null;
      }

      // Create notification message
      let notificationBody;
      if (birthdayUsers.length === 1) {
        notificationBody = `🎉 عيد ميلاد سعيد ${birthdayUsers[0].name}! يبلغ من العمر ${birthdayUsers[0].age} سنة اليوم`;
      } else {
        const names = birthdayUsers.map((u) => u.name).join(', ');
        notificationBody = `🎉 أعياد ميلاد اليوم: ${names}`;
      }

      const payload = {
        notification: {
          title: '🎂 تذكير بعيد ميلاد',
          body: notificationBody,
        },
        data: {
          type: 'birthday',
          count: String(birthdayUsers.length),
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
      };

      // Send notification to all tokens
      const response = await admin.messaging().sendToDevice(tokens, payload);

      console.log(`Successfully sent ${response.successCount} notifications`);
      console.log(`Failed to send ${response.failureCount} notifications`);

      // Handle invalid tokens (optional cleanup)
      if (response.results) {
        const invalidTokens = [];
        response.results.forEach((result, idx) => {
          if (result.error) {
            console.error('Error sending to token:', tokens[idx], result.error);
            if (
              result.error.code === 'messaging/invalid-registration-token' ||
              result.error.code === 'messaging/registration-token-not-registered'
            ) {
              invalidTokens.push(tokens[idx]);
            }
          }
        });

        // You could clean up invalid tokens here if needed
        console.log(`Found ${invalidTokens.length} invalid tokens`);
      }

      return null;
    } catch (error) {
      console.error('checkBirthdays error:', error);
      return null;
    }
  });

/**
 * Manual trigger function to send birthday notifications
 * Can be called by admins to test or manually trigger birthday checks
 */
exports.sendBirthdayNotifications = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to call this function.'
    );
  }

  try {
    // Verify user is admin (Priest or Servant)
    const uid = context.auth.uid;
    const userDoc = await admin.firestore().collection('users').doc(uid).get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found.');
    }

    const userType = userDoc.data().userType;
    if (userType !== 'PR' && userType !== 'SV') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only priests and servants can send birthday notifications.'
      );
    }

    const today = new Date();
    const currentMonth = today.getMonth() + 1;
    const currentDay = today.getDate();

    // Get all children with birthdays today
    const usersSnapshot = await admin
      .firestore()
      .collection('users')
      .where('userType', 'in', ['SS', 'CH'])
      .get();

    const birthdayUsers = [];
    usersSnapshot.forEach((doc) => {
      const user = doc.data();
      const birthday = user.birthday;

      if (birthday) {
        let birthdayDate;
        if (birthday.toDate) {
          birthdayDate = birthday.toDate();
        } else if (birthday instanceof Date) {
          birthdayDate = birthday;
        } else if (typeof birthday === 'string') {
          birthdayDate = new Date(birthday);
        }

        if (
          birthdayDate &&
          birthdayDate.getMonth() + 1 === currentMonth &&
          birthdayDate.getDate() === currentDay
        ) {
          const age = today.getFullYear() - birthdayDate.getFullYear();
          birthdayUsers.push({
            id: doc.id,
            name: user.fullName || user.name || 'Unknown',
            age: age,
          });
        }
      }
    });

    if (birthdayUsers.length === 0) {
      return {
        success: true,
        message: 'No birthdays today',
        count: 0,
      };
    }

    // Get all servants and priests
    const servantsSnapshot = await admin
      .firestore()
      .collection('users')
      .where('userType', 'in', ['SV', 'PR'])
      .get();

    const tokens = [];
    servantsSnapshot.forEach((doc) => {
      const userData = doc.data();
      if (Array.isArray(userData.fcmTokens) && userData.fcmTokens.length > 0) {
        tokens.push(...userData.fcmTokens);
      } else if (typeof userData.fcmToken === 'string' && userData.fcmToken.length > 0) {
        tokens.push(userData.fcmToken);
      }
    });

    if (tokens.length === 0) {
      return {
        success: false,
        message: 'No tokens found to send notifications',
        count: birthdayUsers.length,
      };
    }

    // Create notification
    let notificationBody;
    if (birthdayUsers.length === 1) {
      notificationBody = `🎉 عيد ميلاد سعيد ${birthdayUsers[0].name}! يبلغ من العمر ${birthdayUsers[0].age} سنة اليوم`;
    } else {
      const names = birthdayUsers.map((u) => u.name).join(', ');
      notificationBody = `🎉 أعياد ميلاد اليوم: ${names}`;
    }

    const payload = {
      notification: {
        title: '🎂 تذكير بعيد ميلاد',
        body: notificationBody,
      },
      data: {
        type: 'birthday',
        count: String(birthdayUsers.length),
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    };

    const response = await admin.messaging().sendToDevice(tokens, payload);

    return {
      success: true,
      message: 'Birthday notifications sent successfully',
      count: birthdayUsers.length,
      successCount: response.successCount,
      failureCount: response.failureCount,
      users: birthdayUsers,
    };
  } catch (error) {
    console.error('sendBirthdayNotifications error:', error);

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      'Failed to send birthday notifications: ' + error.message
    );
  }
});

/**
 * Cloud Function to reset user password
 * Only callable by authenticated admin users (Priests)
 */
exports.resetUserPassword = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to call this function.'
    );
  }

  try {
    // Verify user is admin (Priest)
    const adminUid = context.auth.uid;
    const adminDoc = await admin.firestore().collection('users').doc(adminUid).get();

    if (!adminDoc.exists || adminDoc.data().userType !== 'PR') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only priests can reset user passwords.'
      );
    }

    const userId = data.userId;
    const newPassword = data.newPassword;

    if (!userId || !newPassword) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing userId or newPassword'
      );
    }

    // Validate password strength (minimum 6 characters as per Firebase requirement)
    if (newPassword.length < 6) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Password must be at least 6 characters long'
      );
    }

    // Update the user's password using Admin SDK
    await admin.auth().updateUser(userId, {
      password: newPassword,
    });

    // Update user document to mark that password needs to be changed
    await admin.firestore().collection('users').doc(userId).update({
      firstLogin: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      passwordResetBy: adminUid,
      passwordResetAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Log the password reset action
    await admin.firestore().collection('admin_actions').add({
      action: 'reset_password',
      adminId: adminUid,
      targetUserId: userId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      message: 'Password reset successfully',
    };

  } catch (error) {
    console.error('resetUserPassword error:', error);

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      'Failed to reset password: ' + error.message
    );
  }
});

// Send a test notification via HTTP
// Protected by a simple API key (set as an environment variable in the Functions runtime: TEST_NOTIFICATION_KEY)
// Request body (JSON) or query params: { token, topic, title, body }
// Header: x-api-key: <key>  OR query param: ?key=<key>
exports.sendTestNotification = functions.https.onRequest(async (req, res) => {
  try {
    const providedKey = req.get('x-api-key') || req.query.key;
    const expectedKey = process.env.TEST_NOTIFICATION_KEY || '';

    if (!expectedKey) {
      console.warn('TEST_NOTIFICATION_KEY is not set. The function requires an API key for safety.');
    }

    if (expectedKey && providedKey !== expectedKey) {
      return res.status(403).json({ success: false, error: 'Forbidden - invalid API key' });
    }

    const token = req.body?.token || req.query.token;
    const topic = req.body?.topic || req.query.topic;
    const title = req.body?.title || req.query.title || 'Test Notification';
    const body = req.body?.body || req.query.body || 'This is a test notification sent from Cloud Function';

    if (!token && !topic) {
      return res.status(400).json({ success: false, error: 'Missing token or topic' });
    }

    const message = token
      ? {
          token: token,
          notification: { title, body },
          data: { source: 'cloud-function', timestamp: String(Date.now()) },
        }
      : {
          topic: topic,
          notification: { title, body },
          data: { source: 'cloud-function', timestamp: String(Date.now()) },
        };

    const result = await admin.messaging().send(message);
    return res.json({ success: true, result });
  } catch (error) {
    console.error('sendTestNotification error:', error);
    return res.status(500).json({ success: false, error: error.message || String(error) });
  }
});
