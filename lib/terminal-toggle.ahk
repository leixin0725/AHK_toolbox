#Requires AutoHotkey v2.0
#Include %A_ScriptDir%\config\settings.ahk
#Include %A_ScriptDir%\lib\run-unelevated.ahk

OpenNewTerminalWindow(terminalKind, &lastActiveWindow) {
    lastActiveWindow := WinActive("A")
    LaunchTerminal(terminalKind, GetPreferredTerminalDirectory())
}

ToggleTerminalWindows(windowCriteria, &lastActiveWindow, &lastToggleTime, terminalKind) {
    if lastToggleTime && A_TickCount - lastToggleTime < ToolboxConfig.ToggleDebounceMs
        return

    lastToggleTime := A_TickCount
    currentActive := WinActive("A")
    terminalWindows := WinGetList(windowCriteria)

    if terminalWindows.Length && WinActive(windowCriteria) {
        for _, hwnd in terminalWindows {
            try WinMinimize "ahk_id " hwnd
        }

        if lastActiveWindow && WinExist("ahk_id " lastActiveWindow)
            try WinActivate "ahk_id " lastActiveWindow
        return
    }

    lastActiveWindow := currentActive

    ; Activate from bottom to top to preserve the original z-order.
    if terminalWindows.Length {
        Loop terminalWindows.Length {
            hwnd := terminalWindows[terminalWindows.Length - A_Index + 1]
            try {
                if WinGetMinMax("ahk_id " hwnd) = -1
                    WinRestore "ahk_id " hwnd
                WinActivate "ahk_id " hwnd
            }
        }
        return
    }

    LaunchTerminal(terminalKind, GetPreferredTerminalDirectory())
}

GetPreferredTerminalDirectory() {
    fallbackDirectory := ToolboxConfig.TerminalFallbackDirectory
    if fallbackDirectory = "" || !DirExist(fallbackDirectory) {
        fallbackDirectory := EnvGet("USERPROFILE")
        if fallbackDirectory = "" || !DirExist(fallbackDirectory)
            fallbackDirectory := A_ScriptDir
    }

    ; WinGetList follows z-order, so the first match is the most recent Explorer.
    explorerWindows := WinGetList("ahk_class CabinetWClass ahk_exe explorer.exe")
    if !explorerWindows.Length
        return fallbackDirectory

    try shellWindows := ComObject("Shell.Application").Windows
    catch
        return fallbackDirectory

    for _, explorerHwnd in explorerWindows {
        directory := GetExplorerWindowDirectory(shellWindows, explorerHwnd)
        if directory != ""
            return directory
    }

    return fallbackDirectory
}

GetExplorerWindowDirectory(shellWindows, explorerHwnd) {
    try frameTitle := WinGetTitle("ahk_id " explorerHwnd)
    catch
        return ""

    firstValidDirectory := ""

    ; Several Windows 11 tabs can share one HWND. Prefer the title-matched tab.
    for shellWindow in shellWindows {
        try {
            if shellWindow.HWND != explorerHwnd
                continue

            directory := shellWindow.Document.Folder.Self.Path
            if !DirExist(directory)
                continue

            if firstValidDirectory = ""
                firstValidDirectory := directory

            locationName := shellWindow.LocationName
            if locationName != "" && InStr(frameTitle, locationName)
                return directory
        }
    }

    return firstValidDirectory
}

LaunchTerminal(terminalKind, workingDirectory) {
    try {
        if terminalKind = "git-bash" {
            RunUnelevated(GetGitBashExecutable(), "", workingDirectory)
            return true
        }

        if terminalKind = "windows-terminal" {
            executable := ToolboxConfig.WindowsTerminalExecutable
            quotedDirectory := Chr(34) workingDirectory Chr(34)
            RunUnelevated(executable, "-w new -d " quotedDirectory, workingDirectory)
            return true
        }
    } catch as err {
        ShowTerminalLaunchFailure(terminalKind, err.Message)
        return false
    }

    return false
}

GetGitBashExecutable() {
    if ToolboxConfig.GitBashExecutable != ""
        return ToolboxConfig.GitBashExecutable

    candidates := [
        A_ProgramFiles "\Git\git-bash.exe",
        EnvGet("LOCALAPPDATA") "\Programs\Git\git-bash.exe"
    ]

    programFilesX86 := EnvGet("ProgramFiles(x86)")
    if programFilesX86 != ""
        candidates.Push(programFilesX86 "\Git\git-bash.exe")

    for candidate in candidates {
        if FileExist(candidate)
            return candidate
    }

    return "git-bash.exe"
}

ShowTerminalLaunchFailure(terminalKind, message) {
    ToolTip "无法启动 " terminalKind "：" message
    SetTimer (*) => ToolTip(), -2500
}
