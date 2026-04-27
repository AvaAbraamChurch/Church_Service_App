What's New (Google Play) / ما الجديد

Release highlights

- Mandatory update support (forced update): The app now checks a minimum required version using Firebase Remote Config. If a user runs an older version than the configured minimum, they'll see a non-dismissible dialog prompting them to update or close the app.
- Competitions improvements:
  - Admin view: Priests / SuperServants / Servants now see each competition's target audience (target classes) on the competition card.
  - Results screen: After finishing a competition, users now only see the questions they answered incorrectly (streamlined for faster review).
- UX and reliability improvements:
  - Better handling of slow networks and timeouts on the splash/auth flows.
  - Background sync and local storage improvements (Workmanager + Hive based sync kept intact).
- Bug fixes and small polish: Various minor fixes and UI polish across competitions and quiz flows.

Short (one-line) summary for the Play Store "What’s new" field

اضافة فحص تحديث إلزامي، تحسين عرض المسابقات وواجهة النتائج، وإصلاحات وتحسينات للأداء.

Detailed release notes (suggested for the Play Store full release notes)

What changed in this release:

1) Forced update (Version check)
  - The app now reads a Remote Config parameter named `min_required_version` and compares it with the installed app version (from package_info_plus).
  - If the installed app version is older than the configured `min_required_version`, the user receives a non-dismissible dialog with two options: "تحديث الآن" (opens Google Play) and "إغلاق التطبيق" (close the app).
  - Implementation notes for release managers:
    - Remote Config key: `min_required_version` (string). Example value: `0.0.3`.
    - Set the value in Firebase Console -> Remote Config and publish. After clients fetch/activate the remote config, older versions will be blocked.
    - The app opens this Play Store URL when the user taps "تحديث الآن":
      https://play.google.com/store/apps/details?id=com.avaabraamchurch.nenshiri_emporo.app
    - Make sure to publish the new app binary on Google Play with the version you want users to update to.

2) Competitions & Results
  - Admins (priests/superservants/servants) now see the competition target audience (target classes) directly on the competition card. This helps admins verify which classes a competition targets.
  - Results page now focuses on learning: users see only the questions they got wrong (cleaner, quicker review). The correct answer text is not shown in the compact review view (this was requested to avoid showing answers directly in the summary view).

3) Other
  - Improved splash/auth flow resiliency (timeouts, offline fallbacks) so users aren't unnecessarily signed out when networks are slow.
  - Bug fixes and style tweaks across the app; general performance and stability improvements.

How to test locally before publishing

1. Publish `min_required_version` in Remote Config with a version string higher than your local `pubspec.yaml` version (example: set `0.0.3` while `pubspec.yaml` is `0.0.2+...`).
2. Build and run the app locally. After the splash delay the app should show the forced update dialog. "تحديث الآن" opens the Play Store URL; "إغلاق التطبيق" exits the app.
3. Test competitions as an admin user to confirm target audience text appears on cards.
4. Take a competition and submit answers with some incorrect answers — the results screen should only list the incorrect questions.

Admin/Release checklist

- [ ] Build and publish the new app version to Google Play (set versionName/versionCode appropriately).
- [ ] In Firebase Console -> Remote Config, set `min_required_version` to the version users must upgrade to (for forced update behavior).
- [ ] Wait for Remote Config to publish and for devices to fetch/activate (or ask testers to uninstall/reinstall to force a fresh fetch).
- [ ] Verify update dialog appears on older builds.

Notes and optional improvements

- If you prefer a soft-update (warning that can be dismissed), we recommend adding a second parameter like `soft_update_version` and showing a dismissible dialog when the app version is lower than `soft_update_version` but higher or equal to `min_required_version`.
- If you need the correct answers to be shown in the detailed review (not the summary), they can be added to the post-quiz detailed screen — this change was intentionally omitted from the compact results summary.

Contact

If you want, I can:
- Add a soft-update flow and make forced updates configurable per platform; or
- Produce a small Remote Config JSON template and PowerShell curl commands to automate publishing the `min_required_version` parameter (requires your Firebase project id).

---
Generated for release based on recent code updates in repository. Update any app id / version numbers if your Play Store or package version differs.
