# CodexStatusLight

CodexStatusLight is a native macOS menu-bar utility that displays the state of the most recently active local Codex session.

## Status lights

- Gray: Codex is not running, or no session has been discovered.
- Yellow: the latest session is actively producing events.
- Green: the latest session produced a final response and is waiting or complete.
- Red: a previously running session lost the Codex process or stopped producing events for 90 seconds.

## Build

Open `CodexStatusLight.xcodeproj` in Xcode, select the `CodexStatusLight` scheme, and run. The app targets macOS 14 or newer and reads `~/.codex` in read-only mode.

The optional floating light can be enabled from the menu. On displays with a camera housing it is positioned next to the top safe area; otherwise it appears near the top-right of the screen. Its dragged position is remembered.

## One-click installation

Double-click `一键安装Codex红绿灯.command`. It installs the app into `~/Applications`, clears quarantine attributes, applies a local ad-hoc signature, and launches the app. The app auto-detects `~/.codex` on first launch, so no manual folder selection is required unless you want to change it later.

## Release handoff package

Double-click `一键生成发布交接包.command` to create a full release handoff bundle in `Build/` and open the folder automatically.
