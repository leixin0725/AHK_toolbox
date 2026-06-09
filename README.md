# AHK toolbox

一组可独立运行的 AutoHotkey v2 小工具脚本。每个脚本只负责一个功能，可以按需放入启动项。

## Scripts

| File | Hotkey | Function |
| --- | --- | --- |
| `capslock-tap-esc-ctrl.ahk` | `CapsLock` | 短按发送 `Esc`，按住作为左 `Ctrl`，支持 `Ctrl+Shift+CapsLock => Ctrl+Shift+Esc` 和 Alt 先松开的 `Alt+Esc`。 |
| `scroll-pause-function-keys.ahk` | `ScrollLock`, `Pause` | 映射为 `F14`, `F15`。 |
| `copilot-to-ctrl.ahk` | Copilot / `F23` | 将 Copilot 键映射为右 `Ctrl`，并释放硬件自带的 `Win+Shift`。 |
| `obsidian-toggle.ahk` | `PrintScreen`, `F13` | 呼出、隐藏或启动 Obsidian，并记住隐藏后切回的窗口。 |
| `git-bash-toggle.ahk` | `Ctrl+Shift+Insert` | 呼出 Git Bash；当前在 Git Bash 时批量最小化所有 Git Bash 窗口。 |
| `chrome-toggle.ahk` | `Ctrl+Alt+G` | 呼出、隐藏或启动 Chrome；启动时从普通权限 Shell 发起。 |
| `scratch-editor.ahk` | `Ctrl+Alt+V` | 用剪贴板内容打开置顶临时编辑器；再次触发直接关闭。 |

## Requirements

- AutoHotkey v2
- Windows

部分脚本包含本机路径配置：

- `obsidian-toggle.ahk`: `D:\ObsidianLoader\Obsidian.vbs`
- `git-bash-toggle.ahk`: `D:\Git\git-bash.exe`, `D:\LEIXIN2025\Notes`
