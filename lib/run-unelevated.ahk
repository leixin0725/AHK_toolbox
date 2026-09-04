#Requires AutoHotkey v2.0

; 通过桌面 Explorer 启动进程，避免继承管理员身份运行的 AHK 的权限。
RunUnelevated(target, params := "", workingDir := "") {
    static VT_UI4 := 0x13
    static SWC_DESKTOP := ComValue(VT_UI4, 0x8)

    desktopShell := ComObject("Shell.Application").Windows.Item(SWC_DESKTOP).Document.Application
    desktopShell.ShellExecute(target, params, workingDir, "open", 1)
}
