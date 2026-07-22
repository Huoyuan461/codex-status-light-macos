#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
SOURCE_DIR="$ROOT_DIR/website"
BUILD_DIR="${1:-$ROOT_DIR/Build}"
STAGE_DIR="$BUILD_DIR/website-deploy"
ZIP_PATH="$BUILD_DIR/codexlight-website.zip"

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

mkdir -p "$BUILD_DIR"
mkdir -p "$STAGE_DIR"
rsync -a --delete "$SOURCE_DIR"/ "$STAGE_DIR"/
rm -f "$ZIP_PATH"
(cd "$STAGE_DIR" && zip -qr "$ZIP_PATH" .)

print "Prepared website package at: $ZIP_PATH"
print "Stage directory: $STAGE_DIR"
