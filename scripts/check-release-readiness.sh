#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
BUILD_DIR="${ROOT_DIR}/Build"
REPORT_PATH="${BUILD_DIR}/release-readiness-report.txt"

mkdir -p "$BUILD_DIR"
exec > >(tee "$REPORT_PATH")

check_ok() {
  print "✅ $1"
}

check_warn() {
  print "⚠️  $1"
}

check_file() {
  local label="$1"
  local path="$2"
  if [[ -e "$path" ]]; then
    check_ok "$label: $path"
  else
    check_warn "$label missing: $path"
  fi
}

print "Codex Status Light release readiness"
print "Root: $ROOT_DIR"
print "Git commit: $(git -C "$ROOT_DIR" rev-parse --short HEAD)"
print "Report: $REPORT_PATH"
print ""

check_file "App archive" "$ROOT_DIR/Build/CodexStatusLight.dsymfixed.xcarchive"
check_file "Website root" "$ROOT_DIR/website/index.html"
check_file "Website support page" "$ROOT_DIR/website/support/index.html"
check_file "Website privacy page" "$ROOT_DIR/website/privacy/index.html"
check_file "Website zip helper" "$ROOT_DIR/scripts/package-website-zip.sh"
check_file "Website deploy helper" "$ROOT_DIR/scripts/prepare-website-deploy.sh"
check_file "Release handoff helper" "$ROOT_DIR/scripts/package-release-handoff.sh"
check_file "Release handoff command" "$ROOT_DIR/一键生成发布交接包.command"
check_file "Website zip bundle" "$ROOT_DIR/Build/codexlight-website.zip"
check_file "Release handoff bundle" "$ROOT_DIR/Build/codex-status-light-handoff"

print ""
print "App Store submission status:"
if [[ -f "$ROOT_DIR/商城上架/APP_STORE_CONNECT_FILL_IN.md" ]]; then
  check_ok "App Store fill-in sheet available"
else
  check_warn "App Store fill-in sheet missing"
fi
if [[ -f "$ROOT_DIR/商城上架/APP_STORE_RELEASE_CHECKLIST.md" ]]; then
  check_ok "Release checklist available"
else
  check_warn "Release checklist missing"
fi

print ""
print "Outstanding external steps:"
print -- " - Publish codexlight.asia over HTTPS"
print -- " - Authenticate App Store Connect and upload the latest archive"
print -- " - Set App Privacy to Data Not Collected"
print -- " - Finish price/region selection and submit for review"
