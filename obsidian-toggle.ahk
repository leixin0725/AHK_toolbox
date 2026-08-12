#Requires AutoHotkey v2.0
#SingleInstance Force
#Include config\settings.ahk

; PrintScreen / F13 呼出、隐藏或启动 Obsidian。
; 可选的 VirtualDesktopAccessor.dll 可把其他虚拟桌面的窗口移到当前桌面；
; DLL 不存在或不兼容时，只处理能确认位于当前桌面的窗口。

global ObsidianLastActiveWindow := 0
global ObsidianLastToggleTime := 0
global ObsidianVdaHandle := 0
global ObsidianVdmClsid := "{AA509086-5CA9-4C25-8F95-589D3C07B48A}"
global ObsidianVdmIid := "{A5CD92FF-29BE-454C-8D04-D82879FB3F1B}"

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
                if ObsidianIsWindowOnCurrentDesktop(hwnd)
                    try WinMinimize "ahk_id " hwnd
            }

            if ObsidianLastActiveWindow
                    && WinExist("ahk_id " ObsidianLastActiveWindow)
                    && ObsidianIsWindowOnCurrentDesktop(ObsidianLastActiveWindow) {
                try WinActivate "ahk_id " ObsidianLastActiveWindow
            }
            return
        }

        ObsidianLastActiveWindow := currentActive
        currentDesktop := ObsidianGetCurrentDesktopNumber()

        if currentDesktop >= 0 {
            for _, hwnd in obsidianWindows {
                if ObsidianIsWindowOnDesktopNumber(hwnd, currentDesktop) != 1
                    ObsidianMoveWindowToDesktopNumber(hwnd, currentDesktop)
            }

            Sleep 150
            ObsidianActivateWindowsOnDesktop(obsidianWindows, currentDesktop)
            return
        }

        ; Documented fallback: never activate a window on another desktop.
        Loop obsidianWindows.Length {
            hwnd := obsidianWindows[obsidianWindows.Length - A_Index + 1]
            if ObsidianIsWindowOnCurrentDesktop(hwnd)
                ObsidianRestoreAndActivate(hwnd)
        }
    } finally {
        DetectHiddenWindows previousDetectHiddenWindows
    }
}

ObsidianActivateWindowsOnDesktop(windows, desktopNumber) {
    Loop windows.Length {
        hwnd := windows[windows.Length - A_Index + 1]
        if ObsidianIsWindowOnDesktopNumber(hwnd, desktopNumber) = 1
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
                Run Chr(34) A_AhkPath Chr(34) " " Chr(34) launcher Chr(34), workingDirectory
            else
                Run launcher, workingDirectory
            return
        }

        executable := GetObsidianExecutable()
        workingDirectory := InStr(executable, "\")
            ? RegExReplace(executable, "\\[^\\]+$")
            : ""
        ObsidianRunUnelevated(executable, workingDirectory)
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

ObsidianRunUnelevated(executable, workingDirectory := "") {
    static VT_UI4 := 0x13
    static SWC_DESKTOP := ComValue(VT_UI4, 0x8)

    desktopShell := ComObject("Shell.Application").Windows.Item(SWC_DESKTOP).Document.Application
    desktopShell.ShellExecute(executable, "", workingDirectory, "open", 1)
}

ObsidianLoadVirtualDesktopAccessor() {
    global ObsidianVdaHandle

    if ObsidianVdaHandle
        return ObsidianVdaHandle
    if !FileExist(ToolboxConfig.VirtualDesktopAccessorDll)
        return 0

    try ObsidianVdaHandle := DllCall(
        "LoadLibrary", "Str", ToolboxConfig.VirtualDesktopAccessorDll, "Ptr")
    catch
        ObsidianVdaHandle := 0
    return ObsidianVdaHandle
}

ObsidianGetCurrentDesktopNumber() {
    if !ObsidianLoadVirtualDesktopAccessor()
        return -1
    try return DllCall(
        ToolboxConfig.VirtualDesktopAccessorDll "\GetCurrentDesktopNumber", "Int")
    catch
        return -1
}

ObsidianIsWindowOnDesktopNumber(hwnd, number) {
    if !ObsidianLoadVirtualDesktopAccessor()
        return -1
    try return DllCall(
        ToolboxConfig.VirtualDesktopAccessorDll "\IsWindowOnDesktopNumber",
        "Ptr", hwnd, "Int", number, "Int")
    catch
        return -1
}

ObsidianMoveWindowToDesktopNumber(hwnd, number) {
    if !ObsidianLoadVirtualDesktopAccessor()
        return false
    try return DllCall(
        ToolboxConfig.VirtualDesktopAccessorDll "\MoveWindowToDesktopNumber",
        "Ptr", hwnd, "Int", number, "Int") = 1
    catch
        return false
}

ObsidianGetVirtualDesktopManager() {
    global ObsidianVdmClsid, ObsidianVdmIid
    try return ComObject(ObsidianVdmClsid, ObsidianVdmIid)
    catch
        return 0
}

ObsidianIsWindowOnCurrentDesktop(hwnd) {
    vdm := ObsidianGetVirtualDesktopManager()
    if !vdm
        return false

    try {
        onCurrent := 0
        ComCall 3, vdm, "Ptr", hwnd, "Int*", &onCurrent
        return onCurrent != 0
    } catch {
        return false
    }
}

