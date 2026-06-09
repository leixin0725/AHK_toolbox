#Requires AutoHotkey v2.0
#SingleInstance Force

; PrintScreen / F13 呼出、隐藏或启动 Obsidian。
; 隐藏 Obsidian 时会切回呼出前的窗口。

global ObsidianLastActiveWindow := 0
global ObsidianLastToggleTime := 0

PrintScreen::
F13:: {
    global ObsidianLastActiveWindow, ObsidianLastToggleTime

    if (A_TickCount - ObsidianLastToggleTime < 200)
        return
    ObsidianLastToggleTime := A_TickCount

    currentActive := WinActive("A")

    if WinExist("ahk_exe Obsidian.exe") {
        if WinActive("ahk_exe Obsidian.exe") {
            WinMinimize("ahk_exe Obsidian.exe")
            if (ObsidianLastActiveWindow && WinExist("ahk_id " ObsidianLastActiveWindow))
                WinActivate("ahk_id " ObsidianLastActiveWindow)
        } else {
            ObsidianLastActiveWindow := currentActive
            WinActivate("ahk_exe Obsidian.exe")
        }
    } else {
        ObsidianLastActiveWindow := currentActive
        Run("D:\ObsidianLoader\Obsidian.vbs", "D:\ObsidianLoader")
    }
}

