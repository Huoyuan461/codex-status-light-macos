#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PACKAGE_SCRIPT="$SCRIPT_DIR/scripts/package-release-handoff.sh"
BUILD_DIR="$SCRIPT_DIR/Build"

if [[ ! -x "$PACKAGE_SCRIPT" ]]; then
  osascript -e 'display alert "生成失败" message "找不到 scripts/package-release-handoff.sh，请保留完整的 CodexStatusLight 文件夹。" as critical'
  exit 1
fi

"$PACKAGE_SCRIPT" "$BUILD_DIR"
open "$BUILD_DIR"

osascript -e 'display notification "发布交接包已准备好。" with title "Codex Status Light"'
exit 0
