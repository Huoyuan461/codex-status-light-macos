# DNS and Hosting Notes

Use this once the domain is connected to a static host.

Primary domain:

- `codexlight.asia`

## If using GitHub Pages

1. Point `codexlight.asia` to GitHub Pages using the host's recommended DNS records.
2. Keep the `website/` folder at the repository root.
3. Leave the `CNAME` file in place with `codexlight.asia`.
4. Verify these URLs load over HTTPS:
   - `https://codexlight.asia/`
   - `https://codexlight.asia/support/`
   - `https://codexlight.asia/privacy/`

## If using Netlify or a similar host

1. Add `codexlight.asia` as a custom domain in the host dashboard.
2. Follow the host's DNS instructions for apex and `www` records.
3. Publish the `website/` folder as the site root.
4. Verify the same HTTPS URLs above.

## App Store Connect

Use these exact URLs once the site is live:

- Support URL: `https://codexlight.asia/support/`
- Privacy Policy URL: `https://codexlight.asia/privacy/`
