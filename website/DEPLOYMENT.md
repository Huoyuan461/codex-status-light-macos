# Deployment Guide

This site is designed to be published as-is to any HTTPS static host.

Primary domain:

- `codexlight.asia`

Recommended structure after deploy:

- `https://codexlight.asia/`
- `https://codexlight.asia/support/`
- `https://codexlight.asia/privacy/`

Two practical options:

1. GitHub Pages
   - Push the contents of `website/` to the GitHub Pages source you choose.
   - If you later enable GitHub Actions publishing, you can reuse a workflow that copies `website/` into the Pages artifact.
   - The included `CNAME` file binds the site to `codexlight.asia`.
   - See `GITHUB_PAGES_SETUP.md` for the DNS records GitHub Pages documents for apex domains.
   - Use the Pages URL as the App Store support and privacy URLs.
   - To generate a clean upload folder locally, run `scripts/prepare-website-deploy.sh`.
   - To generate a zip bundle for handoff or upload, run `scripts/package-website-zip.sh`.

2. Netlify
   - Drag the `website/` folder into Netlify or connect a repo.
   - Leave the publish directory at the site root.
   - Use the generated HTTPS URL in App Store Connect.

App Store Connect fields:

- Support URL: `https://codexlight.asia/support/`
- Privacy Policy URL: `https://codexlight.asia/privacy/`

Keep the same path structure if the domain changes later. Only swap the domain, not the route names.
