# Codex Status Light Website

This folder is a ready-to-publish static site for App Store submission.

Primary domain:

- `codexlight.asia`

Suggested hosting path:

- GitHub Pages, with setup details in `GITHUB_PAGES_SETUP.md`

Routes:

- `/` landing page
- `/support/` support page
- `/privacy/` privacy policy
- `/release/` release overview

Publish the folder root to any HTTPS static host and use the final public URLs in App Store Connect.

For a clean local export of the site, run `scripts/prepare-website-deploy.sh`.
For a handoff-ready zip bundle, run `scripts/package-website-zip.sh`.
You can also double-click `一键打包网站发布.command` to create the same zip and open the Build folder.
For a full release handoff bundle, run `scripts/package-release-handoff.sh`.

Notes:

- The site includes `.nojekyll` so GitHub Pages will not rewrite the route structure.
- The homepage links to the support and privacy pages and points to `huoyuan461@qq.com`.
- If you later replace the domain, keep the same paths so the App Store links stay stable.
