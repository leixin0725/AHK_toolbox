#Requires AutoHotkey v2.0

; Repository defaults. Copy settings.local.example.ahk to settings.local.ahk
; and edit only the values you want to override.
class ToolboxConfig {
    ; Module switches
    static EnableCapsLock := true
    static EnableFunctionKeys := true
    static EnableCopilotKey := true
    static EnableVirtualDesktopCycle := true
    static EnableObsidian := true
    static EnableGitBash := true
    static EnableWindowsTerminal := true
    static EnableChrome := true
    static EnableScratchEditor := true

    ; Shared timing
    static ToggleDebounceMs := 200

    ; CapsLock: tap Esc, hold left Ctrl
    static CapsTapEscThresholdMs := 180
    static EscCompatibilityHoldMs := 45

    ; Application hotkeys
    static VirtualDesktopLeftHotkey := "^#Left"
    static VirtualDesktopRightHotkey := "^#Right"
    static ObsidianHotkeys := ["PrintScreen", "F13"]
    static GitBashToggleHotkey := "^+Insert"
    static GitBashNewWindowHotkey := "^+!Insert"
    static WindowsTerminalToggleHotkey := "#Insert"
    static WindowsTerminalNewWindowHotkey := "#!Insert"
    static WindowsTerminalAdminNewWindowHotkey := "#+!Insert"
    static ChromeToggleHotkey := "!^g"
    static ScratchEditorHotkey := "$#f"

    ; Application paths. Empty values use automatic discovery or the system PATH.
    static ObsidianLauncher := ""
    static ObsidianLauncherWorkingDirectory := ""
    static ObsidianExecutable := ""
    static VirtualDesktopSwitcherExecutable := A_ScriptDir "\lib\VirtualDesktop11-24H2.exe"
    static VirtualDesktopAccessorDll := A_ScriptDir "\lib\VirtualDesktopAccessor.dll"
    static GitBashExecutable := ""
    static WindowsTerminalExecutable := "wt.exe"
    static ChromeExecutable := ""
    static TerminalFallbackDirectory := A_MyDocuments

    ; ScratchEditor production IPC. See https://github.com/leixin0725/ScratchEditor
    static ScratchEditorExecutable := EnvGet("LOCALAPPDATA") != ""
        ? EnvGet("LOCALAPPDATA") "\ScratchEditor\AhkEditor\ScratchEditor.exe"
        : ""
    static ScratchEditorServerName := "ScratchEditor.Stage1.v1"
    static ScratchEditorStartupDelayMs := 3000
    static ScratchEditorStartupRetryIntervalMs := 1000
    static ScratchEditorStartupRetryCount := 30
    static ScratchEditorStartupTimeoutMs := 1500
    static ScratchEditorFailureNoticeMs := 2500
}

#Include *i %A_ScriptDir%\config\settings.local.ahk

; Existing ScratchEditor integration variables have final precedence.
scratchEditorExecutableOverride := EnvGet("SCRATCHEDITOR_EXE")
if scratchEditorExecutableOverride != ""
    ToolboxConfig.ScratchEditorExecutable := scratchEditorExecutableOverride

scratchEditorServerOverride := EnvGet("SCRATCHEDITOR_SERVER_NAME")
if scratchEditorServerOverride != ""
    ToolboxConfig.ScratchEditorServerName := scratchEditorServerOverride
