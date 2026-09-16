#Requires AutoHotkey v2.0
#SingleInstance Force
#Include config\settings.ahk
#Include lib\virtual-desktop.ahk
#Include lib\run-unelevated.ahk

; PrintScreen / F13 呼出、隐藏或启动 Obsidian。
; 可选的 VirtualDesktopAccessor.dll 可把其他虚拟桌面的窗口移到当前桌面；
; DLL 不存在或不兼容时，只处理能确认位于当前桌面的窗口。

global ObsidianLastActiveWindow := 0
global ObsidianLastToggleTime := 0

if ToolboxConfig.EnableObsidian {
    for hotkeyName in ToolboxConfig.ObsidianHotkeys
        Hotkey hotkeyName, ToggleObsidianWindows
}

ToggleObsidianWindows(*) {
    global ObsidianLastToggleTime

    if A_TickCount - ObsidianLastToggleTime < ToolboxConfig.ToggleDebounceMs
        return
    ObsidianLastToggleTime := A_TickCount

    try ToggleObsidianWindowsCore()
    catch as err
        FileAppend Format("{} ToggleObsidianWindows: {}`n", A_Now, err.Message),
            A_Temp "\ahk-toolbox-obsidian-toggle.log"
}

ToggleObsidianWindowsCore() {
    global ObsidianLastActiveWindow

    previousDetectHiddenWindows := A_DetectHiddenWindows
    DetectHiddenWindows true

    try {
        currentActive := WinActive("A")
        obsidianWindows := WinGetList("ahk_exe Obsidian.exe ahk_class Chrome_WidgetWin_1")

        if !obsidianWindows.Length {
            if !ProcessExist("Obsidian.exe") {
                ObsidianLastActiveWindow := currentActive
                LaunchObsidian()
            }
            return
        }

        if WinActive("ahk_exe Obsidian.exe") {
            for _, hwnd in obsidianWindows {
                if IsWindowOnCurrentDesktop(hwnd)
                    try WinMinimize "ahk_id " hwnd
            }

            if ObsidianLastActiveWindow
                    && WinExist("ahk_id " ObsidianLastActiveWindow)
                    && IsWindowOnCurrentDesktop(ObsidianLastActiveWindow) {
                try WinActivate "ahk_id " ObsidianLastActiveWindow
            }
            return
        }

        ObsidianLastActiveWindow := currentActive
        currentDesktop := GetCurrentDesktopNumber()

        if currentDesktop >= 0 {
            for _, hwnd in obsidianWindows {
                if IsWindowOnDesktopNumber(hwnd, currentDesktop) != 1
                    MoveWindowToDesktopNumber(hwnd, currentDesktop)
            }

            Sleep 150
            ObsidianActivateWindowsOnDesktop(obsidianWindows, currentDesktop)
            return
        }

        ; Documented fallback: never activate a window on another desktop.
        Loop obsidianWindows.Length {
            hwnd := obsidianWindows[obsidianWindows.Length - A_Index + 1]
            if IsWindowOnCurrentDesktop(hwnd)
                ObsidianRestoreAndActivate(hwnd)
        }
    } finally {
        DetectHiddenWindows previousDetectHiddenWindows
    }
}

ObsidianActivateWindowsOnDesktop(windows, desktopNumber) {
    Loop windows.Length {
        hwnd := windows[windows.Length - A_Index + 1]
        if IsWindowOnDesktopNumber(hwnd, desktopNumber) = 1
            ObsidianRestoreAndActivate(hwnd)
    }
}

ObsidianRestoreAndActivate(hwnd) {
    try {
        if WinGetMinMax("ahk_id " hwnd) = -1
            WinRestore "ahk_id " hwnd
        WinActivate "ahk_id " hwnd
    }
}

LaunchObsidian() {
    launcher := ToolboxConfig.ObsidianLauncher

    try {
        if launcher != "" {
            if !FileExist(launcher)
                throw Error("配置的启动器不存在：" launcher)

            workingDirectory := ToolboxConfig.ObsidianLauncherWorkingDirectory
            if workingDirectory = ""
                SplitPath launcher, , &workingDirectory

            if RegExMatch(launcher, "i)\.ahk$")
                RunUnelevated(A_AhkPath, Chr(34) launcher Chr(34), workingDirectory)
            else
                RunUnelevated(launcher, "", workingDirectory)
            return
        }

        executable := GetObsidianExecutable()
        workingDirectory := InStr(executable, "\")
            ? RegExReplace(executable, "\\[^\\]+$")
            : ""
        RunUnelevated(executable, "", workingDirectory)
    } catch as err {
        ToolTip "无法启动 Obsidian：" err.Message
        SetTimer (*) => ToolTip(), -2500
    }
}

GetObsidianExecutable() {
    if ToolboxConfig.ObsidianExecutable != ""
        return ToolboxConfig.ObsidianExecutable

    candidates := []
    localAppData := EnvGet("LOCALAPPDATA")
    if localAppData != ""
        candidates.Push(localAppData "\Programs\Obsidian\Obsidian.exe")
    candidates.Push(A_ProgramFiles "\Obsidian\Obsidian.exe")

    for candidate in candidates {
        if FileExist(candidate)
            return candidate
    }

    return "Obsidian.exe"
}
