#Requires AutoHotkey v2.0
#SingleInstance Force
#Include config\settings.ahk

; Ctrl+Win+Left/Right 使用 Windows 原生动画循环切换虚拟桌面。

if ToolboxConfig.EnableVirtualDesktopCycle {
    Hotkey ToolboxConfig.VirtualDesktopLeftHotkey, SwitchVirtualDesktopLeft
    Hotkey ToolboxConfig.VirtualDesktopRightHotkey, SwitchVirtualDesktopRight
}

SwitchVirtualDesktopLeft(*) {
    SwitchVirtualDesktop("Left")
}

SwitchVirtualDesktopRight(*) {
    SwitchVirtualDesktop("Right")
}

SwitchVirtualDesktop(direction) {
    executable := ToolboxConfig.VirtualDesktopSwitcherExecutable
    Run('"' executable '" /Wrap /' direction, A_ScriptDir, "Hide")
}
