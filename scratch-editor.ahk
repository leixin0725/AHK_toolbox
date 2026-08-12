#Requires AutoHotkey v2.0
#SingleInstance Force
#Include config\settings.ahk

; Win+F 通过本地命名管道切换 ScratchEditor。
; 启动或 IPC 失败时不创建 AHK GUI、不读取或改写剪贴板。

global ScratchEditorPipe := "\\.\pipe\" ToolboxConfig.ScratchEditorServerName
global ScratchEditorPipeHandle := -1

if ToolboxConfig.EnableScratchEditor {
    Hotkey ToolboxConfig.ScratchEditorHotkey, ToggleScratchEditor
    OnExit CloseScratchEditorPipe
    SetTimer StartScratchEditorResident, -1
}

ToggleScratchEditor(*) {
    if EnsureScratchEditorAndSend("toggle")
        return true

    ShowScratchEditorFailureNotice()
    return false
}

StartScratchEditorResident(*) {
    EnsureScratchEditorResident()
}

EnsureScratchEditorResident() {
    if IsScratchEditorReady()
        return true

    executable := ToolboxConfig.ScratchEditorExecutable
    if executable = "" || !FileExist(executable)
        return false

    try Run Chr(34) executable Chr(34) " --background"
    catch
        return false

    deadline := A_TickCount + ToolboxConfig.ScratchEditorStartupTimeoutMs
    while A_TickCount < deadline {
        if IsScratchEditorReady()
            return true
        Sleep 10
    }

    return false
}

IsScratchEditorReady() {
    global ScratchEditorPipe

    handle := DllCall(
        "CreateFileW",
        "Str", ScratchEditorPipe,
        "UInt", 0xC0000000, ; GENERIC_READ | GENERIC_WRITE
        "UInt", 0,
        "Ptr", 0,
        "UInt", 3,          ; OPEN_EXISTING
        "UInt", 0,
        "Ptr", 0,
        "Ptr"
    )
    if handle = -1
        return false

    request := '{"command":"status","requestId":"ahk-ready"}'
    payloadChars := StrPut(request "`n", "UTF-8")
    payload := Buffer(payloadChars)
    payloadBytes := StrPut(request "`n", payload, "UTF-8") - 1
    bytesWritten := 0
    wrote := DllCall(
        "WriteFile", "Ptr", handle, "Ptr", payload, "UInt", payloadBytes,
        "UInt*", &bytesWritten, "Ptr", 0
    )
    if !wrote || bytesWritten != payloadBytes {
        DllCall "CloseHandle", "Ptr", handle
        return false
    }

    response := Buffer(65536, 0)
    bytesRead := 0
    read := DllCall(
        "ReadFile", "Ptr", handle, "Ptr", response, "UInt", response.Size,
        "UInt*", &bytesRead, "Ptr", 0
    )
    DllCall "CloseHandle", "Ptr", handle

    if !read || !bytesRead
        return false

    status := StrGet(response, bytesRead, "UTF-8")
    return InStr(status, '"ready":true') > 0
}

EnsureScratchEditorAndSend(command) {
    if SendScratchEditorCommand(command)
        return true
    if !EnsureScratchEditorResident()
        return false
    return SendScratchEditorCommand(command)
}

SendScratchEditorCommand(command) {
    global ScratchEditorPipe, ScratchEditorPipeHandle

    if ScratchEditorPipeHandle = -1 {
        ScratchEditorPipeHandle := DllCall(
            "CreateFileW",
            "Str", ScratchEditorPipe,
            "UInt", 0x40000000, ; GENERIC_WRITE
            "UInt", 0,
            "Ptr", 0,
            "UInt", 3,          ; OPEN_EXISTING
            "UInt", 0,
            "Ptr", 0,
            "Ptr"
        )
    }
    if ScratchEditorPipeHandle = -1
        return false

    payloadChars := StrPut(command "`n", "UTF-8")
    payload := Buffer(payloadChars)
    payloadBytes := StrPut(command "`n", payload, "UTF-8") - 1
    bytesWritten := 0
    ok := DllCall(
        "WriteFile",
        "Ptr", ScratchEditorPipeHandle,
        "Ptr", payload,
        "UInt", payloadBytes,
        "UInt*", &bytesWritten,
        "Ptr", 0
    )

    if !ok || bytesWritten != payloadBytes {
        CloseScratchEditorPipe()
        return false
    }
    return true
}

CloseScratchEditorPipe(*) {
    global ScratchEditorPipeHandle

    if ScratchEditorPipeHandle != -1 {
        DllCall "CloseHandle", "Ptr", ScratchEditorPipeHandle
        ScratchEditorPipeHandle := -1
    }
}

ShowScratchEditorFailureNotice() {
    ToolTip "ScratchEditor 启动失败；剪贴板内容未被改动，可直接粘贴使用。"
    SetTimer HideScratchEditorFailureNotice, -ToolboxConfig.ScratchEditorFailureNoticeMs
}

HideScratchEditorFailureNotice(*) {
    ToolTip()
}
