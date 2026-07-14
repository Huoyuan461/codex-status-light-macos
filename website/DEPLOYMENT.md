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
   - Create a repository with the contents of `website/` at the root.
   - Enable Pages from the default branch.
   - The included `CNAME` file binds the site to `codexlight.asia`.
   - See `GITHUB_PAGES_SETUP.md` for the DNS records GitHub Pages documents for apex domains.
   - Use the Pages URL as the App Store support and privacy URLs.

2. Netlify
   - Drag the `website/` folder into Netlify or connect a repo.
   - Leave the publish directory at the site root.
   - Use the generated HTTPS URL in App Store Connect.

App Store Connect fields:

- Support URL: `https://codexlight.asia/support/`
- Privacy Policy URL: `https://codexlight.asia/privacy/`

Keep the same path structure if the domain changes later. Only swap the domain, not the route names.
