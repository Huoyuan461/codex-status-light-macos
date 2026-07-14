# GitHub Pages Setup for `codexlight.asia`

Use GitHub Pages if you want the simplest static-hosting path for this app.

## Repository layout

Publish the contents of `website/` at the repository root.

Required files already in place:

- `.nojekyll`
- `CNAME`
- `index.html`
- `support/index.html`
- `privacy/index.html`

## GitHub configuration

1. Push the site files to a public GitHub repository.
2. In the repository settings, open Pages.
3. Choose the publishing source you want to use.
4. Set the custom domain to `codexlight.asia`.
5. Wait for GitHub to provision HTTPS.

## DNS records

For the apex domain `codexlight.asia`, GitHub Pages documents four A records:

- `185.199.108.153`
- `185.199.109.153`
- `185.199.110.153`
- `185.199.111.153`

If your DNS provider supports AAAA records and you want IPv6, GitHub Pages also documents these:

- `2606:50c0:8000::153`
- `2606:50c0:8001::153`
- `2606:50c0:8002::153`
- `2606:50c0:8003::153`

If you also want `www.codexlight.asia`, add a CNAME record:

- Host: `www`
- Target: `codexlight.asia`

## Optional domain verification

If you want GitHub to verify the domain ownership, add the TXT record shown in your GitHub Pages settings. Keep that TXT record in place after verification.

## Final URLs

Once DNS has propagated and HTTPS is active, use these URLs in App Store Connect:

- `https://codexlight.asia/support/`
- `https://codexlight.asia/privacy/`
