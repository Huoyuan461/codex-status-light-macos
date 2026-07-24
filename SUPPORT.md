# Codex Status Light Support

Codex Status Light is a lightweight macOS utility that shows the current state of the most recently active local Codex session.

## How to verify the app

1. Launch the app.
2. On first launch, let it auto-detect the local `~/.codex` folder.
3. If auto-detection fails, choose the `.codex` folder manually and grant read-only access.
4. Use the app to check whether Codex is idle, running, completed, or disconnected.
5. If you close the main window, open it again from the Window menu.

## Contact

- Email: huoyuan461@qq.com

## Status meanings

- Gray: no session found or Codex not running
- Yellow: Codex is actively producing events
- Green: the latest session completed and is waiting for the next prompt
- Red: Codex was disconnected or inactive for 90 seconds

