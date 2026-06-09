#Requires AutoHotkey v2.0
#SingleInstance Force

; CapsLock 策略
; - 短按并松开：Esc
; - 按住并配合非修饰键：左 Ctrl，例如 CapsLock+C => Ctrl+C
; - 按住并配合修饰键短按：保留修饰键发送 Esc，例如 Ctrl+Shift+CapsLock => Ctrl+Shift+Esc
; - 长按后松开：只释放 Ctrl，不发送 Esc

#InputLevel 1
SendLevel 1

if GetKeyState("CapsLock", "T") {
    SetCapsLockState "Off"
}
SetCapsLockState "AlwaysOff"

SetTimer EnforceCapsLockOff, 2000
EnforceCapsLockOff() {
    if GetKeyState("CapsLock", "T") {
        SetCapsLockState "AlwaysOff"
    }
}

global CapsAsCtrlDown := false
global CapsAsCtrlPressedAt := 0
global CapsTapHadNonModifier := false
global CapsTapInput := 0
global CapsTapEscThresholdMs := 180

*CapsLock:: {
    global CapsAsCtrlDown, CapsAsCtrlPressedAt, CapsTapHadNonModifier, CapsTapInput
    Critical
    SetKeyDelay -1

    if CapsAsCtrlDown
        return

    CapsAsCtrlDown := true
    CapsAsCtrlPressedAt := A_TickCount
    CapsTapHadNonModifier := false

    CapsTapInput := InputHook("V")
    CapsTapInput.KeyOpt("{All}", "N")
    CapsTapInput.OnKeyDown := CapsAsCtrlOnKeyDown
    CapsTapInput.Start()

    Send "{Blind}{LCtrl DownR}"
}

*CapsLock Up:: {
    global CapsAsCtrlDown, CapsAsCtrlPressedAt, CapsTapHadNonModifier, CapsTapInput, CapsTapEscThresholdMs
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
        heldMs <= CapsTapEscThresholdMs
        && !CapsTapHadNonModifier
        && CapsAsCtrlAllowsTapPriorKey(A_PriorKey)
    )

    if shouldSendEsc {
        if (GetKeyState("LCtrl", "P") || GetKeyState("RCtrl", "P")) {
            Send "{Blind}{Esc}"
            CapsAsCtrlRelease()
        } else {
            CapsAsCtrlRelease()
            Send "{Blind}{Esc}"
        }
    } else {
        CapsAsCtrlRelease()
    }

    CapsAsCtrlDown := false
    CapsAsCtrlPressedAt := 0
    CapsTapHadNonModifier := false
}

CapsAsCtrlOnKeyDown(inputHook, vk, sc) {
    global CapsAsCtrlDown, CapsTapHadNonModifier

    if (CapsAsCtrlDown && !CapsAsCtrlIsModifierVk(vk))
        CapsTapHadNonModifier := true
}

CapsAsCtrlRelease() {
    lctrlPhysicallyDown := GetKeyState("LCtrl", "P")

    Send "{Blind}{LCtrl Up}"

    if lctrlPhysicallyDown
        Send "{Blind}{LCtrl Down}"
}

CapsAsCtrlAllowsTapPriorKey(keyName) {
    return (keyName = "CapsLock" || CapsAsCtrlIsModifierName(keyName))
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
             "Alt", "LAlt", "RAlt",
             "LWin", "RWin":
            return true
    }

    return false
}

