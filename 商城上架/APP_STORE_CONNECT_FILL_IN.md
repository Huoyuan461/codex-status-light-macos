# App Store Connect Fill-In Sheet

Bundle ID:

- `com.huoyuan.CodexStatusLight`

App identity:

- Name: `Codex Status Light`
- Subtitle: `Codex 开发进度红绿灯`
- Category: `Developer Tools`
- Price: `Free`
- Minimum OS: `macOS 14.0`

Store listing:

- Description: see `APP_STORE_METADATA.md`
- Keywords: `Codex,开发工具,状态监控,菜单栏,效率,编程`
- Support URL: `https://codexlight.asia/support/`
- Privacy Policy URL: `https://codexlight.asia/privacy/`

Contact:

- Support email: `huoyuan461@qq.com`

App Privacy:

- Data collected: `None`
- Tracking: `No`

Review notes:

- The app auto-detects the local `~/.codex` folder on launch and falls back to a manual chooser only if auto-detection fails.
- Any granted permission is read-only and is used only to inspect local Codex session JSONL and SQLite state files.
- If Codex is not installed on the review machine, reviewers can still validate the onboarding flow, display mode selection, icon, and idle state.

Submission assets:

- App icon: bundled in Xcode asset catalog
- Screenshot set: `screenshots/png/screenshot-01-menu-bar.png`
- Screenshot set: `screenshots/png/screenshot-02-notch.png`
- Screenshot set: `screenshots/png/screenshot-03-desktop.png`

Operational checklist:

1. Create the app record in App Store Connect.
2. Upload the archive from Xcode Organizer.
3. Mark App Privacy as `Data Not Collected`.
4. Attach the support and privacy URLs.
5. Select regions and pricing.
6. Submit for review.
