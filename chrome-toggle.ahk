#Requires AutoHotkey v2.0
#SingleInstance Force
#Include config\settings.ahk
#Include lib\virtual-desktop.ahk

; Ctrl+Alt+G 呼出、隐藏或启动 Chrome。
; 如果本脚本以管理员身份运行，Chrome 会通过普通权限 Explorer 启动。
; Chrome 浏览器、PWA 与应用模式窗口统一支持跨虚拟桌面移动。

global ChromeLastActiveWindow := 0
global ChromeLastToggleTime := 0

if ToolboxConfig.EnableChrome
    Hotkey ToolboxConfig.ChromeToggleHotkey, ToggleChrome

ToggleChrome(*) {
    global ChromeLastActiveWindow, ChromeLastToggleTime

    if A_TickCount - ChromeLastToggleTime < ToolboxConfig.ToggleDebounceMs
        return
    ChromeLastToggleTime := A_TickCount

    try ToggleChromeCore()
    catch as err
        FileAppend Format("{} ToggleChrome: {}`n", A_Now, err.Message),
            A_Temp "\ahk-toolbox-chrome-toggle.log"
}

ToggleChromeCore() {
    global ChromeLastActiveWindow

    previousDetectHiddenWindows := A_DetectHiddenWindows
    DetectHiddenWindows true

    try {
        currentActive := WinActive("A")
        chromeWindows := WinGetList("ahk_exe chrome.exe ahk_class Chrome_WidgetWin_1")

        if !chromeWindows.Length {
            ChromeLastActiveWindow := currentActive
            LaunchChrome()
            return
        }

        if WinActive("ahk_exe chrome.exe") {
            for _, hwnd in chromeWindows {
                if IsWindowOnCurrentDesktop(hwnd)
                    try WinMinimize "ahk_id " hwnd
            }

            if ChromeLastActiveWindow
                    && WinExist("ahk_id " ChromeLastActiveWindow)
                    && IsWindowOnCurrentDesktop(ChromeLastActiveWindow) {
                try WinActivate "ahk_id " ChromeLastActiveWindow
            }
            return
        }

        ChromeLastActiveWindow := currentActive
        currentDesktop := GetCurrentDesktopNumber()

        if currentDesktop >= 0 {
            for _, hwnd in chromeWindows {
                if IsWindowOnDesktopNumber(hwnd, currentDesktop) != 1
                    MoveWindowToDesktopNumber(hwnd, currentDesktop)
            }

            Sleep 150
            ChromeActivateWindowsOnDesktop(chromeWindows, currentDesktop)
            return
        }

        ; Documented fallback: never activate a window on another desktop.
        Loop chromeWindows.Length {
            hwnd := chromeWindows[chromeWindows.Length - A_Index + 1]
            if IsWindowOnCurrentDesktop(hwnd)
                ChromeRestoreAndActivate(hwnd)
        }
    } finally {
        DetectHiddenWindows previousDetectHiddenWindows
    }
}

ChromeActivateWindowsOnDesktop(windows, desktopNumber) {
    Loop windows.Length {
        hwnd := windows[windows.Length - A_Index + 1]
        if IsWindowOnDesktopNumber(hwnd, desktopNumber) = 1
            ChromeRestoreAndActivate(hwnd)
    }
}

ChromeRestoreAndActivate(hwnd) {
    try {
        if WinGetMinMax("ahk_id " hwnd) = -1
            WinRestore "ahk_id " hwnd
        WinActivate "ahk_id " hwnd
    }
}

LaunchChrome() {
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

    chromeHwnd := WinWait("ahk_exe chrome.exe ahk_class Chrome_WidgetWin_1", , 5)
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
