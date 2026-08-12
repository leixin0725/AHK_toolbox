#Requires AutoHotkey v2.0
#SingleInstance Force
#Include config\settings.ahk

; 将 Copilot 键映射为右 Ctrl。
; 部分键盘会发送 Win+Shift+F23；这里同时拦截裸 F23 和组合形态。

#InputLevel 1
SendLevel 1

global CopilotAsCtrlDown := false

#HotIf ToolboxConfig.EnableCopilotKey
<#<+F23::
*F23:: {
    global CopilotAsCtrlDown

    Critical
    SetKeyDelay -1

    ; Break the system's Win-key menu detection before releasing firmware modifiers.
    Send "{Blind}{vkE8}"
    Send "{Blind}{LWin Up}{LShift Up}"

    if !CopilotAsCtrlDown {
        CopilotAsCtrlDown := true
        Send "{Blind}{RCtrl DownR}"
    }
}

<#<+F23 Up::
*F23 Up:: {
    global CopilotAsCtrlDown

    Critical
    SetKeyDelay -1

    if CopilotAsCtrlDown {
        Send "{Blind}{RCtrl Up}"
        CopilotAsCtrlDown := false
    }

    Send "{Blind}{LWin Up}{LShift Up}"
}
#HotIf

