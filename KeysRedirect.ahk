#Requires AutoHotkey v2.0
#SingleInstance Force

EnsureKeysRedirectElevated()

EnsureKeysRedirectElevated() {
    if A_IsAdmin
        return

    restartMarker := "--keysredirect-elevation-restart"
    for argument in A_Args {
        if argument = restartMarker {
            MsgBox "KeysRedirect 必须以管理员权限运行。", "AutoHotkey 启动失败", 0x10
            ExitApp 1
        }
    }

    try Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '" ' restartMarker, A_ScriptDir
    ExitApp
}

; AHK toolbox unified entry point.
; Run this file to enable every module selected in config/settings.ahk.

#Include config\settings.ahk
#Include capslock-tap-esc-ctrl.ahk
#Include scroll-pause-function-keys.ahk
#Include copilot-to-ctrl.ahk
#Include virtual-desktop-cycle.ahk
#Include obsidian-toggle.ahk
#Include git-bash-toggle.ahk
#Include windows-terminal-toggle.ahk
#Include chrome-toggle.ahk
#Include scratch-editor.ahk
