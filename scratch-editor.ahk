#Requires AutoHotkey v2.0
#SingleInstance Force

; Ctrl+Alt+V 用剪贴板内容打开置顶临时编辑器；再次触发直接关闭。
; 关闭时不保存、不写回剪贴板。

global ScratchGui := ""

global WinW := 920
global WinH := 640

global DragZoneH := 52
global Margin := 18
global EdgeDragW := 14
global EditTopDragExtra := 18

global BgColor := "252525"
global BarColor := "2B2B2B"
global TextColor := "B8B8B8"

global EditFontSize := 14
global EditFont := "Consolas"

OnMessage(0x0201, TryNativeDrag)
OnMessage(0x0203, TryNativeDrag)

^!v::ToggleScratch()

ToggleScratch() {
    global ScratchGui
    global WinW, WinH, DragZoneH, Margin
    global BgColor, BarColor, TextColor
    global EditFontSize, EditFont

    if IsObject(ScratchGui) {
        CloseScratch()
        return
    }

    ScratchGui := Gui("-Caption +ToolWindow +AlwaysOnTop", "Scratch")
    ScratchGui.BackColor := BarColor

    editX := Margin
    editY := DragZoneH
    editW := WinW - Margin * 2
    editH := WinH - DragZoneH - Margin

    ScratchGui.SetFont("s" EditFontSize " c" TextColor, EditFont)

    editOptions := "vScratchText "
        . "x" editX " y" editY " "
        . "w" editW " h" editH " "
        . "Multi WantTab -Wrap +VScroll -E0x200 "
        . "Background" BgColor " c" TextColor

    edit := ScratchGui.Add("Edit", editOptions, A_Clipboard)

    ScratchGui.OnEvent("Close", (*) => CloseScratch())
    ScratchGui.OnEvent("Escape", (*) => CloseScratch())

    x := (A_ScreenWidth - WinW) // 2
    y := (A_ScreenHeight - WinH) // 2

    ScratchGui.Show("x" x " y" y " w" WinW " h" WinH)
    EnableDwmRoundedCorners(ScratchGui.Hwnd)

    edit.Focus()
}

TryNativeDrag(wParam, lParam, msg, hwnd) {
    global ScratchGui
    global DragZoneH, EdgeDragW, EditTopDragExtra

    if !IsObject(ScratchGui)
        return

    GetCursorScreenPos(&mx, &my)
    WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " ScratchGui.Hwnd)

    relX := mx - wx
    relY := my - wy

    if (relX < 0 || relX >= ww || relY < 0 || relY >= wh)
        return

    isDragZone :=
        relY < DragZoneH + EditTopDragExtra
        || relX < EdgeDragW
        || relX >= ww - EdgeDragW
        || relY >= wh - EdgeDragW

    if !isDragZone
        return

    DllCall("ReleaseCapture")
    DllCall(
        "SendMessage",
        "Ptr", ScratchGui.Hwnd,
        "UInt", 0x00A1,
        "Ptr", 2,
        "Ptr", 0
    )

    return 0
}

GetCursorScreenPos(&x, &y) {
    pt := Buffer(8, 0)
    DllCall("GetCursorPos", "Ptr", pt)

    x := NumGet(pt, 0, "Int")
    y := NumGet(pt, 4, "Int")
}

EnableDwmRoundedCorners(hwnd) {
    cornerPreference := 2

    DllCall(
        "dwmapi\DwmSetWindowAttribute",
        "Ptr", hwnd,
        "UInt", 33,
        "Int*", cornerPreference,
        "UInt", 4
    )
}

CloseScratch() {
    global ScratchGui

    if IsObject(ScratchGui) {
        try ScratchGui.Destroy()
    }

    ScratchGui := ""
}

