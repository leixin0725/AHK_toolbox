#Requires AutoHotkey v2.0
#SingleInstance Force

; 将 Copilot 键映射为右 Ctrl。
; 部分键盘会发送 Win+Shift+F23；这里同时拦截裸 F23 和组合形态。

#InputLevel 1
SendLevel 1

global CopilotAsCtrlDown := false

<#<+F23::
*F23:: {
    global CopilotAsCtrlDown
    Critical
    SetKeyDelay -1

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

