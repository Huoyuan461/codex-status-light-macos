# Release Runbook

This is the shortest safe path from the current workspace to a submission-ready macOS app.

1. Confirm the deployed HTTPS URLs.
   - Support: `https://codexlight.asia/support/`
   - Privacy: `https://codexlight.asia/privacy/`

2. Create the App Store Connect app record.
   - Bundle ID: `com.huoyuan.CodexStatusLight`
   - Name: `Codex Status Light`
   - Category: `Developer Tools`

3. Open the Xcode archive.
   - Use the existing archive in `Build/CodexStatusLight.xcarchive`.
   - Run `Validate App`.

4. Upload the build.
   - Use Xcode Organizer upload flow.
   - Wait for App Store Connect processing to finish.

5. Fill the store listing.
   - Support URL
   - Privacy Policy URL
   - Description and keywords from `APP_STORE_METADATA.md`

6. Fill App Privacy.
   - Data Not Collected
   - No tracking

7. Verify screenshots and pricing.
   - Attach the three screenshot drafts or final captures.
   - Keep the app free unless a different pricing strategy is chosen later.

8. Submit for review.
   - Put the review notes from `APP_STORE_CONNECT_FILL_IN.md` into the submission notes.
