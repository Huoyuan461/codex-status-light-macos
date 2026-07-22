#!/bin/zsh
set -e

SCRIPT_DIR="${0:A:h}"
SOURCE_APP="$SCRIPT_DIR/Build/Release/CodexStatusLight.app"
INSTALL_DIR="$HOME/Applications"
TARGET_APP="$INSTALL_DIR/CodexStatusLight.app"

if [[ ! -d "$SOURCE_APP" ]]; then
  osascript -e 'display alert "安装失败" message "没有找到 CodexStatusLight.app，请保留完整的 CodexStatusLight 文件夹。" as critical'
  exit 1
fi

mkdir -p "$INSTALL_DIR"
pkill -f "$TARGET_APP/Contents/MacOS/CodexStatusLight" 2>/dev/null || true
rm -rf "$TARGET_APP"
/usr/bin/ditto "$SOURCE_APP" "$TARGET_APP"
/usr/bin/xattr -cr "$TARGET_APP"
/usr/bin/codesign --force --deep --sign - "$TARGET_APP"
/usr/bin/open "$TARGET_APP"

osascript -e 'display notification "已安装并启动，状态灯会自动关联本机 Codex。" with title "Codex 红绿灯安装完成"'
exit 0
