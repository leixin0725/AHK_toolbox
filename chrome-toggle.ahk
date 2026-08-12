#Requires AutoHotkey v2.0
#SingleInstance Force
#Include config\settings.ahk

; Ctrl+Alt+G 呼出、隐藏或启动 Chrome。
; 如果本脚本以管理员身份运行，Chrome 会通过普通权限 Explorer 启动。

global ChromeLastActiveWindow := 0
global ChromeLastToggleTime := 0

if ToolboxConfig.EnableChrome
    Hotkey ToolboxConfig.ChromeToggleHotkey, ToggleChrome

ToggleChrome(*) {
    global ChromeLastActiveWindow, ChromeLastToggleTime

    if A_TickCount - ChromeLastToggleTime < ToolboxConfig.ToggleDebounceMs
        return
    ChromeLastToggleTime := A_TickCount

    currentActive := WinActive("A")

    if WinExist("ahk_exe chrome.exe") {
        if WinActive("ahk_exe chrome.exe") {
            WinMinimize "ahk_exe chrome.exe"
            if ChromeLastActiveWindow && WinExist("ahk_id " ChromeLastActiveWindow)
                WinActivate "ahk_id " ChromeLastActiveWindow
        } else {
            ChromeLastActiveWindow := currentActive
            WinActivate "ahk_exe chrome.exe"
        }
        return
    }

    ChromeLastActiveWindow := currentActive
    chromePath := GetChromePath()
    chromeWorkDir := InStr(chromePath, "\")
        ? RegExReplace(chromePath, "\\[^\\]+$")
        : ""

    try RunUnelevated(chromePath, "", chromeWorkDir)
    catch as err {
        ToolTip "无法启动 Chrome：" err.Message
        SetTimer (*) => ToolTip(), -2500
        return
    }

    chromeHwnd := WinWait("ahk_exe chrome.exe", , 5)
    if chromeHwnd {
        WinRestore "ahk_id " chromeHwnd
        WinActivate "ahk_id " chromeHwnd
    }
}

RunUnelevated(target, params := "", workingDir := "") {
    static VT_UI4 := 0x13
    static SWC_DESKTOP := ComValue(VT_UI4, 0x8)

    desktopShell := ComObject("Shell.Application").Windows.Item(SWC_DESKTOP).Document.Application
    desktopShell.ShellExecute(target, params, workingDir, "open", 1)
}

GetChromePath() {
    if ToolboxConfig.ChromeExecutable != ""
        return ToolboxConfig.ChromeExecutable

    candidates := []
    localAppData := EnvGet("LOCALAPPDATA")
    if localAppData != ""
        candidates.Push(localAppData "\Google\Chrome\Application\chrome.exe")

    candidates.Push(A_ProgramFiles "\Google\Chrome\Application\chrome.exe")

    programFilesX86 := EnvGet("ProgramFiles(x86)")
    if programFilesX86 != ""
        candidates.Push(programFilesX86 "\Google\Chrome\Application\chrome.exe")

    for candidate in candidates {
        if FileExist(candidate)
            return candidate
    }

    return "chrome.exe"
}

