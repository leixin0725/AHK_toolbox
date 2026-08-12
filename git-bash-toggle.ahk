#Requires AutoHotkey v2.0
#SingleInstance Force
#Include config\settings.ahk
#Include lib\terminal-toggle.ahk

; Ctrl+Shift+Insert 批量呼出/最小化 Git Bash。
; Ctrl+Shift+Alt+Insert 始终新建窗口。

global GitBashLastActiveWindow := 0
global GitBashLastToggleTime := 0

if ToolboxConfig.EnableGitBash {
    Hotkey ToolboxConfig.GitBashToggleHotkey, ToggleGitBashWindows
    Hotkey ToolboxConfig.GitBashNewWindowHotkey, OpenNewGitBashWindow
}

ToggleGitBashWindows(*) {
    global GitBashLastActiveWindow, GitBashLastToggleTime

    ToggleTerminalWindows(
        "ahk_exe mintty.exe",
        &GitBashLastActiveWindow,
        &GitBashLastToggleTime,
        "git-bash"
    )
}

OpenNewGitBashWindow(*) {
    global GitBashLastActiveWindow
    OpenNewTerminalWindow("git-bash", &GitBashLastActiveWindow)
}

