#Requires AutoHotkey v2.0

; Shared virtual-desktop helpers for application window toggles.
; Moving another process's window requires VirtualDesktopAccessor.dll;
; the documented IVirtualDesktopManager is used only for current-desktop checks.

global VirtualDesktopAccessorHandle := 0
global VirtualDesktopManagerClsid := "{AA509086-5CA9-4C25-8F95-589D3C07B48A}"
global VirtualDesktopManagerIid := "{A5CD92FF-29BE-454C-8D04-D82879FB3F1B}"

LoadVirtualDesktopAccessor() {
    global VirtualDesktopAccessorHandle

    if VirtualDesktopAccessorHandle
        return VirtualDesktopAccessorHandle
    if !FileExist(ToolboxConfig.VirtualDesktopAccessorDll)
        return 0

    try VirtualDesktopAccessorHandle := DllCall(
        "LoadLibrary", "Str", ToolboxConfig.VirtualDesktopAccessorDll, "Ptr")
    catch
        VirtualDesktopAccessorHandle := 0
    return VirtualDesktopAccessorHandle
}

GetCurrentDesktopNumber() {
    if !LoadVirtualDesktopAccessor()
        return -1
    try return DllCall(
        ToolboxConfig.VirtualDesktopAccessorDll "\GetCurrentDesktopNumber", "Int")
    catch
        return -1
}

IsWindowOnDesktopNumber(hwnd, number) {
    if !LoadVirtualDesktopAccessor()
        return -1
    try return DllCall(
        ToolboxConfig.VirtualDesktopAccessorDll "\IsWindowOnDesktopNumber",
        "Ptr", hwnd, "Int", number, "Int")
    catch
        return -1
}

MoveWindowToDesktopNumber(hwnd, number) {
    if !LoadVirtualDesktopAccessor()
        return false
    try return DllCall(
        ToolboxConfig.VirtualDesktopAccessorDll "\MoveWindowToDesktopNumber",
        "Ptr", hwnd, "Int", number, "Int") = 1
    catch
        return false
}

GetVirtualDesktopManager() {
    global VirtualDesktopManagerClsid, VirtualDesktopManagerIid

    try return ComObject(VirtualDesktopManagerClsid, VirtualDesktopManagerIid)
    catch
        return 0
}

IsWindowOnCurrentDesktop(hwnd) {
    vdm := GetVirtualDesktopManager()
    if !vdm
        return false

    try {
        onCurrent := 0
        ComCall 3, vdm, "Ptr", hwnd, "Int*", &onCurrent
        return onCurrent != 0
    } catch {
        return false
    }
}
