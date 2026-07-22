#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
CHECK_SCRIPT="$SCRIPT_DIR/scripts/check-release-readiness.sh"

if [[ ! -x "$CHECK_SCRIPT" ]]; then
  osascript -e 'display alert "检查失败" message "找不到 scripts/check-release-readiness.sh，请保留完整的 CodexStatusLight 文件夹。" as critical'
  exit 1
fi

"$CHECK_SCRIPT"

osascript -e 'display notification "发布状态已检查完成。" with title "Codex Status Light"'
exit 0
