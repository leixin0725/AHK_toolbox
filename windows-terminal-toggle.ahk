#Requires AutoHotkey v2.0
#SingleInstance Force
#Include config\settings.ahk
#Include lib\terminal-toggle.ahk

; Win+Insert 批量呼出/最小化 Windows Terminal。
; Win+Alt+Insert 始终新建窗口。

global WindowsTerminalLastActiveWindow := 0
global WindowsTerminalLastToggleTime := 0

if ToolboxConfig.EnableWindowsTerminal {
    Hotkey ToolboxConfig.WindowsTerminalToggleHotkey, ToggleWindowsTerminalWindows
    Hotkey ToolboxConfig.WindowsTerminalNewWindowHotkey, OpenNewWindowsTerminalWindow
}

ToggleWindowsTerminalWindows(*) {
    global WindowsTerminalLastActiveWindow, WindowsTerminalLastToggleTime

    ToggleTerminalWindows(
        "ahk_exe WindowsTerminal.exe",
        &WindowsTerminalLastActiveWindow,
        &WindowsTerminalLastToggleTime,
        "windows-terminal"
    )
}

OpenNewWindowsTerminalWindow(*) {
    global WindowsTerminalLastActiveWindow
    OpenNewTerminalWindow("windows-terminal", &WindowsTerminalLastActiveWindow)
}
