#Requires AutoHotkey v2.0
#SingleInstance Force
#Include config\settings.ahk

; CapsLock 策略
; - 短按并松开：Esc
; - 按住并配合非修饰键：左 Ctrl，例如 CapsLock+C => Ctrl+C
; - 按住并配合修饰键短按：保留修饰键发送 Esc
; - Alt 先于 CapsLock 松开：补偿真实 Esc 的 Alt+Esc 行为
; - 长按后松开：只释放 Ctrl，不发送 Esc

#InputLevel 1
SendLevel 1

global CapsAsCtrlDown := false
global CapsAsCtrlPressedAt := 0
global CapsTapHadNonModifier := false
global CapsTapEscSent := false
global CapsTapStartedWithAlt := false
global CapsTapInput := 0

if ToolboxConfig.EnableCapsLock {
    if GetKeyState("CapsLock", "T")
        SetCapsLockState "Off"

    SetCapsLockState "AlwaysOff"
    SetTimer EnforceCapsLockOff, 2000
}

EnforceCapsLockOff() {
    if GetKeyState("CapsLock", "T")
        SetCapsLockState "AlwaysOff"
}

#HotIf ToolboxConfig.EnableCapsLock
*CapsLock:: {
    global CapsAsCtrlDown, CapsAsCtrlPressedAt, CapsTapHadNonModifier
    global CapsTapEscSent, CapsTapStartedWithAlt, CapsTapInput

    Critical
    SetKeyDelay -1

    ; Ignore keyboard firmware or driver-generated repeat Down events.
    if CapsAsCtrlDown
        return

    CapsAsCtrlDown := true
    CapsAsCtrlPressedAt := A_TickCount
    CapsTapHadNonModifier := false
    CapsTapEscSent := false
    CapsTapStartedWithAlt := GetKeyState("LAlt", "P") || GetKeyState("RAlt", "P")

    CapsTapInput := InputHook("V")
    CapsTapInput.KeyOpt("{All}", "N")
    CapsTapInput.OnKeyDown := CapsAsCtrlOnKeyDown
    CapsTapInput.Start()

    Send "{Blind}{LCtrl DownR}"
}

*CapsLock Up:: {
    global CapsAsCtrlDown, CapsAsCtrlPressedAt, CapsTapHadNonModifier
    global CapsTapEscSent, CapsTapStartedWithAlt, CapsTapInput

    Critical
    SetKeyDelay -1

    if !CapsAsCtrlDown
        return

    if CapsTapInput {
        CapsTapInput.Stop()
        CapsTapInput := 0
    }

    heldMs := A_TickCount - CapsAsCtrlPressedAt
    shouldSendEsc := (
        heldMs <= ToolboxConfig.CapsTapEscThresholdMs
        && !CapsTapEscSent
        && !CapsTapHadNonModifier
        && CapsAsCtrlAllowsTapPriorKey(A_PriorKey)
    )

    if shouldSendEsc {
        if GetKeyState("LCtrl", "P") || GetKeyState("RCtrl", "P") {
            SendEscCompat()
            CapsAsCtrlRelease()
        } else {
            CapsAsCtrlRelease()
            SendEscCompat()
        }
    } else {
        CapsAsCtrlRelease()
    }

    CapsAsCtrlDown := false
    CapsAsCtrlPressedAt := 0
    CapsTapHadNonModifier := false
    CapsTapEscSent := false
    CapsTapStartedWithAlt := false
}

~*LAlt Up::
~*RAlt Up:: {
    Critical
    SetKeyDelay -1
    CapsAsCtrlSendAltEscOnAltUp()
}
#HotIf

CapsAsCtrlOnKeyDown(inputHook, vk, sc) {
    global CapsAsCtrlDown, CapsTapHadNonModifier

    if CapsAsCtrlDown && !CapsAsCtrlIsModifierVk(vk)
        CapsTapHadNonModifier := true
}

CapsAsCtrlRelease() {
    lctrlPhysicallyDown := GetKeyState("LCtrl", "P")
    Send "{Blind}{LCtrl Up}"

    if lctrlPhysicallyDown
        Send "{Blind}{LCtrl Down}"
}

SendEscCompat() {
    ; Some applications poll key state and can miss an instantaneous tap.
    SendEvent "{Blind}{Esc Down}"
    Sleep ToolboxConfig.EscCompatibilityHoldMs
    SendEvent "{Blind}{Esc Up}"
}

CapsAsCtrlSendAltEscOnAltUp() {
    global CapsAsCtrlDown, CapsAsCtrlPressedAt, CapsTapHadNonModifier
    global CapsTapEscSent, CapsTapStartedWithAlt

    if !CapsAsCtrlDown || !CapsTapStartedWithAlt || CapsTapEscSent || CapsTapHadNonModifier
        return

    if A_TickCount - CapsAsCtrlPressedAt > ToolboxConfig.CapsTapEscThresholdMs
        return

    Send "{Blind}{LCtrl Up}"
    Send "{Blind}{Alt Down}{Esc}{Alt Up}"
    Send "{Blind}{LCtrl DownR}"
    CapsTapEscSent := true
}

CapsAsCtrlAllowsTapPriorKey(keyName) {
    return keyName = "CapsLock" || CapsAsCtrlIsModifierName(keyName)
}

CapsAsCtrlIsModifierVk(vk) {
    switch vk {
        case 0x10, 0x11, 0x12, 0x14, 0x5B, 0x5C, 0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5:
            return true
    }

    return false
}
CapsAsCtrlIsModifierName(keyName) {
    switch keyName {
        case "Shift", "LShift", "RShift",
             "Ctrl", "Control", "LCtrl", "RCtrl", "LControl", "RControl",
             "Alt", "LAlt", "RAlt", "LWin", "RWin":
            return true
    }

    return false
}
