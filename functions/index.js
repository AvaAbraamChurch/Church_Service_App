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

