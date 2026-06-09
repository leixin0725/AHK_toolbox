#Requires AutoHotkey v2.0
#SingleInstance Force

; Ctrl+Shift+Insert 呼出 Git Bash。
; 当前在 Git Bash 时，批量最小化所有 mintty 窗口并切回原窗口。

global GitBashLastActiveWindow := 0
global GitBashLastToggleTime := 0

^+Insert:: {
    global GitBashLastActiveWindow, GitBashLastToggleTime

    if (A_TickCount - GitBashLastToggleTime < 200)
        return
    GitBashLastToggleTime := A_TickCount

    currentActive := WinActive("A")

    if WinActive("ahk_exe mintty.exe") {
        bashList := WinGetList("ahk_exe mintty.exe")

        for index, hwnd in bashList {
            WinMinimize("ahk_id " hwnd)
        }

        if (GitBashLastActiveWindow && WinExist("ahk_id " GitBashLastActiveWindow))
            WinActivate("ahk_id " GitBashLastActiveWindow)
    } else if WinExist("ahk_exe mintty.exe") {
        GitBashLastActiveWindow := currentActive
        WinActivate("ahk_exe mintty.exe")
    } else {
        GitBashLastActiveWindow := currentActive
        Run("D:\Git\git-bash.exe", "D:\LEIXIN2025\Notes")
    }
}

