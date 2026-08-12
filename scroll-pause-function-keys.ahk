#Requires AutoHotkey v2.0
#SingleInstance Force
#Include config\settings.ahk

; 为扩展快捷键提供两个不常用的虚拟功能键。
; ScrollLock 只映射为 F14；ScratchEditor 默认使用 Win+F，避免热键冲突。

#HotIf ToolboxConfig.EnableFunctionKeys
ScrollLock::F14
Pause::F15
#HotIf

