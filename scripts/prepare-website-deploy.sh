#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
SOURCE_DIR="$ROOT_DIR/website"
OUTPUT_DIR="${1:-$ROOT_DIR/Build/website-deploy}"
SUMMARY_SCRIPT="$ROOT_DIR/scripts/generate-release-summary.sh"
SUMMARY_PATH="$ROOT_DIR/Build/release-summary.json"

required_files=(
  "$SOURCE_DIR/index.html"
  "$SOURCE_DIR/support/index.html"
  "$SOURCE_DIR/privacy/index.html"
  "$SOURCE_DIR/CNAME"
  "$SOURCE_DIR/.nojekyll"
)

for file in "${required_files[@]}"; do
  if [[ ! -f "$file" ]]; then
    print -u2 "Missing required website file: $file"
    exit 1
  fi
done

mkdir -p "$OUTPUT_DIR"
rsync -a --delete "$SOURCE_DIR"/ "$OUTPUT_DIR"/
zsh "$SUMMARY_SCRIPT" "$SUMMARY_PATH"
cp "$SUMMARY_PATH" "$OUTPUT_DIR/release-summary.json"

print "Prepared website deploy package at: $OUTPUT_DIR"
print "Use this folder as the publish root for GitHub Pages, Netlify, or another HTTPS static host."
