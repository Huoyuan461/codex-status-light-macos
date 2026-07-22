#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
BUILD_DIR="${1:-$ROOT_DIR/Build}"
HANDFOFF_DIR="$BUILD_DIR/codex-status-light-handoff"
HANDFOFF_ZIP="$BUILD_DIR/codex-status-light-handoff.zip"

website_zip_script="$ROOT_DIR/scripts/package-website-zip.sh"
summary_script="$ROOT_DIR/scripts/generate-release-summary.sh"

required_files=(
  "$ROOT_DIR/website/index.html"
  "$ROOT_DIR/website/support/index.html"
  "$ROOT_DIR/website/privacy/index.html"
  "$ROOT_DIR/商城上架/APP_STORE_METADATA.md"
  "$ROOT_DIR/商城上架/APP_STORE_CONNECT_FILL_IN.md"
  "$ROOT_DIR/商城上架/APP_STORE_RELEASE_CHECKLIST.md"
  "$ROOT_DIR/商城上架/RELEASE_RUNBOOK.md"
)

for file in "${required_files[@]}"; do
  if [[ ! -f "$file" ]]; then
    print -u2 "Missing required file: $file"
    exit 1
  fi
done

mkdir -p "$HANDFOFF_DIR"

"$website_zip_script" "$BUILD_DIR"
zsh "$summary_script" "$BUILD_DIR/release-summary.json"
cp "$BUILD_DIR/release-summary.json" "$HANDFOFF_DIR/"

cp "$ROOT_DIR/商城上架/APP_STORE_METADATA.md" "$HANDFOFF_DIR/"
cp "$ROOT_DIR/商城上架/APP_STORE_CONNECT_FILL_IN.md" "$HANDFOFF_DIR/"
cp "$ROOT_DIR/商城上架/APP_STORE_RELEASE_CHECKLIST.md" "$HANDFOFF_DIR/"
cp "$ROOT_DIR/商城上架/RELEASE_RUNBOOK.md" "$HANDFOFF_DIR/"
cp "$ROOT_DIR/website/README.md" "$HANDFOFF_DIR/WEBSITE_README.md"
cp "$ROOT_DIR/website/DEPLOYMENT.md" "$HANDFOFF_DIR/WEBSITE_DEPLOYMENT.md"
if [[ -f "$ROOT_DIR/Build/release-readiness-report.txt" ]]; then
  cp "$ROOT_DIR/Build/release-readiness-report.txt" "$HANDFOFF_DIR/"
fi

cat > "$HANDFOFF_DIR/HANDOFF.md" <<EOF
# Codex Status Light Release Handoff

Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Git commit: $(git -C "$ROOT_DIR" rev-parse --short HEAD)

Current verified status:

- App archive and dSYM generation verified.
- Website support and privacy pages prepared for HTTPS hosting.
- Website zip bundle ready at: $BUILD_DIR/codexlight-website.zip
- Release handoff zip ready at: $HANDFOFF_ZIP
- App Store Connect upload still requires an authenticated session on the local machine.
- Release readiness report is included if it was generated before this bundle.
- A machine-readable summary is included at: $HANDFOFF_DIR/release-summary.json

Next actions:

1. Restore App Store Connect authentication in Xcode or Organizer.
2. Upload the latest archive from the verified Release build.
3. Point DNS/hosting to the HTTPS site and confirm the support/privacy URLs.
4. Submit for App Review after App Privacy is set to "Data Not Collected".
EOF

rm -f "$HANDFOFF_ZIP"
(cd "$BUILD_DIR" && zip -qr "$HANDFOFF_ZIP" "$(basename "$HANDFOFF_DIR")")

print "Prepared release handoff at: $HANDFOFF_DIR"
print "Prepared release handoff zip at: $HANDFOFF_ZIP"
