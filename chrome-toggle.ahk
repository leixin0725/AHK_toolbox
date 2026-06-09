#Requires AutoHotkey v2.0
#SingleInstance Force

; Ctrl+Alt+G 呼出、隐藏或启动 Chrome。
; 如果本脚本以管理员身份运行，Chrome 会通过普通权限 Explorer 启动。

global ChromeLastActiveWindow := 0
global ChromeLastToggleTime := 0

!^g:: {
    global ChromeLastActiveWindow, ChromeLastToggleTime

    if (A_TickCount - ChromeLastToggleTime < 200)
        return
    ChromeLastToggleTime := A_TickCount

    currentActive := WinActive("A")

    if WinExist("ahk_exe chrome.exe") {
        if WinActive("ahk_exe chrome.exe") {
            WinMinimize("ahk_exe chrome.exe")
            if (ChromeLastActiveWindow && WinExist("ahk_id " ChromeLastActiveWindow))
                WinActivate("ahk_id " ChromeLastActiveWindow)
        } else {
            ChromeLastActiveWindow := currentActive
            WinActivate("ahk_exe chrome.exe")
        }
    } else {
        ChromeLastActiveWindow := currentActive

        chromePath := GetChromePath()
        chromeWorkDir := ""
        if (InStr(chromePath, "\"))
            chromeWorkDir := RegExReplace(chromePath, "\\[^\\]+$")

        RunUnelevated(chromePath, "", chromeWorkDir)

        chromeHwnd := WinWait("ahk_exe chrome.exe", , 5)
        if chromeHwnd {
            WinRestore("ahk_id " chromeHwnd)
            WinActivate("ahk_id " chromeHwnd)
        }
    }
}

RunUnelevated(target, params := "", workingDir := "") {
    static VT_UI4 := 0x13
    static SWC_DESKTOP := ComValue(VT_UI4, 0x8)

    desktopShell := ComObject("Shell.Application").Windows.Item(SWC_DESKTOP).Document.Application
    desktopShell.ShellExecute(target, params, workingDir, "open", 1)
}

GetChromePath() {
    chromePaths := []

    localAppData := EnvGet("LOCALAPPDATA")
    if (localAppData != "")
        chromePaths.Push(localAppData "\Google\Chrome\Application\chrome.exe")

    chromePaths.Push(A_ProgramFiles "\Google\Chrome\Application\chrome.exe")

    pf86 := EnvGet("ProgramFiles(x86)")
    if (pf86 != "")
        chromePaths.Push(pf86 "\Google\Chrome\Application\chrome.exe")

    for chromePath in chromePaths {
        if FileExist(chromePath)
            return chromePath
    }

    return "chrome.exe"
}

