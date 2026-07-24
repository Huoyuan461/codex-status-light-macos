#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
OUTPUT_PATH="${1:-$ROOT_DIR/Build/release-summary.json}"

mkdir -p "${OUTPUT_PATH:A:h}"

cat > "$OUTPUT_PATH" <<EOF
{
  "generated_at_utc": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "project": "Codex Status Light",
  "git_commit": "$(git -C "$ROOT_DIR" rev-parse --short HEAD)",
  "verified_deliverables": [
    "App archive and dSYM generation",
    "Website support page",
    "Website privacy page",
    "Website zip bundle",
    "Release handoff bundle",
    "Release readiness report"
  ],
  "outstanding_external_steps": [
    "Publish codexlight.asia over HTTPS",
    "Authenticate App Store Connect and upload the latest archive",
    "Set App Privacy to Data Not Collected",
    "Finish price/region selection and submit for review"
  ],
  "support_url": "https://github.com/Huoyuan461/codex-status-light-macos/blob/main/SUPPORT.md",
  "privacy_url": "https://github.com/Huoyuan461/codex-status-light-macos/blob/main/PRIVACY.md",
  "release_url": "https://codexlight.asia/release/"
}
EOF

print "Generated release summary at: $OUTPUT_PATH"
