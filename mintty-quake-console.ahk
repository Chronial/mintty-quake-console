; Mintty quake console: Visor-like functionality for Windows
; Version: 1.3
; Author: Jon Rogers (lonepie@gmail.com)
; URL: https://github.com/lonepie/mintty-quake-console
; Credits:
;   Originally forked from: https://github.com/marcharding/mintty-quake-console
;   mintty: http://code.google.com/p/mintty/
;   Visor: http://visor.binaryage.com/

;*******************************************************************************
;               Settings
;*******************************************************************************
#NoEnv
#SingleInstance force
SendMode Input
DetectHiddenWindows, on
SetWinDelay, -1

; get path to cygwin from registry
RegRead, cygwinRootDir, HKEY_LOCAL_MACHINE, SOFTWARE\Cygwin\setup, rootdir
cygwinBinDir := cygwinRootDir . "\bin"

;*******************************************************************************
;               Preferences & Variables
;*******************************************************************************
VERSION := 1.4
iniFile := A_ScriptDir . "\mintty-quake-console.ini"
IniRead, minttyPath, %iniFile%, General, mintty_path, % cygwinBinDir . "\mintty.exe"
IniRead, minttyArgs, %iniFile%, General, mintty_args, -
IniRead, consoleHotkey, %iniFile%, General, hotkey, ^``
IniRead, startWithWindows, %iniFile%, Display, start_with_windows, 0
IniRead, startHidden, %iniFile%, Display, start_hidden, 1
IniRead, initialHeight, %iniFile%, Display, initial_height, 380
IniRead, initialWidth, %iniFile%, Display, initial_width, 100 ; percent
IniRead, initialTrans, %iniFile%, Display, initial_trans, 235 ; 0-255 stepping
IniRead, autohide, %iniFile%, Display, autohide_by_default, 0
IniRead, animationModeFade, %iniFile%, Display, animation_mode_fade
IniRead, animationModeSlide, %iniFile%, Display, animation_mode_slide
IniRead, animationStep, %iniFile%, Display, animation_step, 20
IniRead, animationTimeout, %iniFile%, Display, animation_timeout, 10
IfNotExist %iniFile%
{
    SaveSettings()
}

; path to mintty
minttyPath_args := minttyPath . " " . minttyArgs

; initial height and width of console window
heightConsoleWindow := initialHeight
widthConsoleWindow := initialWidth

isVisible := False

;*******************************************************************************
;               Hotkeys
;*******************************************************************************
;Hotkey, %consoleHotkey%, ConsoleHotkey
Hotkey, SC029, ConsoleHotkey

;*******************************************************************************
;               Menu
;*******************************************************************************
if !InStr(A_ScriptName, ".exe")
    Menu, Tray, Icon, %A_ScriptDir%\terminal.ico
;Menu, Tray, NoStandard
; Menu, Tray, MainWindow
Menu, Tray, Tip, mintty-quake-console %VERSION%
Menu, Tray, Click, 1
Menu, Tray, Add, Show/Hide, ToggleVisible
Menu, Tray, Default, Show/Hide
Menu, Tray, Add, Enabled, ToggleScriptState
Menu, Tray, Check, Enabled
Menu, Tray, Add, Auto-Hide, ToggleAutoHide
if (autohide)
    Menu, Tray, Check, Auto-Hide
Menu, Tray, Add
Menu, Tray, Add, About, AboutDlg
Menu, Tray, Add, Reload, ReloadSub
Menu, Tray, Add, Exit, ExitSub

init()
return
;*******************************************************************************
;               Functions / Labels
;*******************************************************************************
init()
{
    global
    initCount++
    ; get last active window
    WinGet, hw_current, ID, A
    if !WinExist("ahk_class mintty") {
        EnvGet home, HOME
        Run %minttyPath_args%, %home%, Hide, hw_mintty
        ;;; Doesn't work – we don't get the correct PID
        ;WinWait ahk_pid %hw_mintty%
        Sleep, 500
    }
    WinGet, hw_mintty, PID, ahk_class mintty
    WinGetPos, OrigXpos, OrigYpos, OrigWinWidth, OrigWinHeight, ahk_pid %hw_mintty%
    toggleScript("init")
}

toggle()
{
    global

    IfWinActive ahk_pid %hw_mintty%
    {
        ; reset focus to last active window
        WinActivate, ahk_id %hw_current%

        Slide("ahk_pid" . hw_mintty, "Out")
    } else {
        ; get last active window
        WinGet, hw_current, ID, A

        WinActivate ahk_pid %hw_mintty%
        Slide("ahk_pid" . hw_mintty, "In")
    }
}

Slide(Window, Dir)
{
    global initialWidth, animationModeFade, animationModeSlide, animationStep, animationTimeout, autohide, isVisible, currentTrans, initialTrans
    WinGetPos, Xpos, Ypos, WinWidth, WinHeight, %Window%

    VirtScreenPos(ScreenLeft, ScreenTop, ScreenWidth, ScreenHeight)

    ; Multi monitor support.  Always move to current window
    If (Dir = "In") {
      WinShow %Window%
      WinLeft := ScreenLeft + ((ScreenWidth - initialWidth) / 2)
      WinMove, %Window%,, WinLeft
    }
    Loop {
      inConditional := Ypos >= ScreenTop
      outConditional := Ypos <= (-WinHeight)

      If (Dir = "In") And inConditional Or (Dir = "Out") And outConditional
         Break

      dRate := animationStep
      dY := % (Dir = "In") ? Ypos + dRate : Ypos - dRate
      WinMove, %Window%,,, dY
      WinGetPos, Xpos, Ypos, WinWidth, WinHeight, %Window%
      Sleep, %animationTimeout%
    }

    If (Dir = "In") {
        WinMove, %Window%,,, ScreenTop
        if (autohide)
            SetTimer, HideWhenInactive, 250
        isVisible := True
    }
    If (Dir = "Out") {
        if (autohide)
            SetTimer, HideWhenInactive, Off
        isVisible := False
        WinMinimize %Window%
        WinHide %Window%
    }
}

toggleScript(state) {
    ; enable/disable script effects, hotkeys, etc
    global
    ; WinGetPos, Xpos, Ypos, WinWidth, WinHeight, ahk_pid %hw_mintty%
    if(state = "on" or state = "init") {
        If !WinExist("ahk_pid" . hw_mintty) {
            init()
            return
        }

        WinSet, AlwaysOnTop, On, ahk_pid %hw_mintty% ; Always on top
        WinHide ahk_pid %hw_mintty%
        WinSet, Style, -0xC40000, ahk_pid %hw_mintty% ; hide window borders and caption/title
        WinSet, ExStyle, -0x80, ahk_pid %hw_mintty% ; do not show mininized in taskbar

        VirtScreenPos(ScreenLeft, ScreenTop, ScreenWidth, ScreenHeight)

        ;width := ScreenWidth * widthConsoleWindow / 100
        ;left := ScreenLeft + ((ScreenWidth - width) /  2)
        width := widthConsoleWindow
        left := ScreenLeft + ((ScreenWidth - width) /  2)
        ;left := ScreenLeft
        ;left := 1000
        WinMove, ahk_pid %hw_mintty%, , %left%, -%heightConsoleWindow%, %width%, %heightConsoleWindow% ; resize/move
        ;WinMove, ahk_pid %hw_mintty%, , %left%, -%OrigWinHeight% ; only move

        scriptEnabled := True
        Menu, Tray, Check, Enabled

        if (state = "init" and initCount = 1 and startHidden) {
            return
        }

        WinShow ahk_pid %hw_mintty%
        WinActivate ahk_pid %hw_mintty%
        Slide("ahk_pid" . hw_mintty, "In")
    }
    else if (state = "off") {
        WinSet, Style, +0xC40000, ahk_pid %hw_mintty% ; show window borders and caption/title
        WinSet, ExStyle, +0x80, ahk_pid %hw_mintty% ; show mininized in taskbar
        WinSet, AlwaysOnTop, Off, ahk_pid %hw_mintty% ; not always on top
        if (OrigYpos >= 0)
            WinMove, ahk_pid %hw_mintty%, , %OrigXpos%, %OrigYpos%, %OrigWinWidth%, %OrigWinHeight% ; restore size / position
        else
            WinMove, ahk_pid %hw_mintty%, , %OrigXpos%, 100, %OrigWinWidth%, %OrigWinHeight%
        WinShow, ahk_pid %hw_mintty% ; show window
        scriptEnabled := False
        Menu, Tray, Uncheck, Enabled
    }
}

HideWhenInactive:
    IfWinNotActive ahk_pid %hw_mintty%
    {
        ; consent.exe is the UAC prompt
        Process,Exist, consent.exe
        if ErrorLevel
            return
        if(isVisible){
            Slide("ahk_pid" . hw_mintty, "Out")
        }
        SetTimer, HideWhenInactive, Off
    }
return

ToggleVisible:
    if(isVisible) {
        Slide("ahk_pid" . hw_mintty, "Out")
    } else {
        WinActivate ahk_pid %hw_mintty%
        Slide("ahk_pid" . hw_mintty, "In")
    }
return

ToggleScriptState:
    if(scriptEnabled)
        toggleScript("off")
    else
        toggleScript("on")
return

ToggleAutoHide:
    autohide := !autohide
    Menu, Tray, ToggleCheck, Auto-Hide
    SetTimer, HideWhenInactive, Off
return

ConsoleHotkey:
    If (scriptEnabled) {
        IfWinExist ahk_pid %hw_mintty%
        {
            toggle()
        } else {
            init()
        }
    }
return

ExitSub:
    if A_ExitReason not in Logoff,Shutdown
    {
        ;MsgBox, 4, mintty-quake-console, Are you sure you want to exit?
        ;IfMsgBox, No
        ;    return
        toggleScript("off")
    }
ExitApp

ReloadSub:
Reload
return

AboutDlg:
    MsgBox, 64, About, mintty-quake-console AutoHotkey script`nVersion: %VERSION%`nAuthor: Jonathon Rogers <lonepie@gmail.com>`nURL: https://github.com/lonepie/mintty-quake-console
return

;*******************************************************************************
;               Extra Hotkeys
;*******************************************************************************
#IfWinActive ahk_class mintty
; why this method doesn't work, I don't know...
; IncreaseHeight:
^!NumpadAdd::
;^+=::
    if(WinActive("ahk_pid" . hw_mintty)) {

    VirtScreenPos(ScreenLeft, ScreenTop, ScreenWidth, ScreenHeight)
        if(heightConsoleWindow < ScreenHeight) {
            heightConsoleWindow += animationStep
            WinMove, ahk_pid %hw_mintty%,,,,, heightConsoleWindow
        }
    }
return
; DecreaseHeight:
^!NumpadSub::
;^+-::
    if(WinActive("ahk_pid" . hw_mintty)) {
        if(heightConsoleWindow > 100) {
            heightConsoleWindow -= animationStep
            WinMove, ahk_pid %hw_mintty%,,,,, heightConsoleWindow
        }
    }
return
#IfWinActive

;*******************************************************************************
;               Options
;*******************************************************************************
SaveSettings() {
    global
    IniWrite, %minttyPath%, %iniFile%, General, mintty_path
    IniWrite, %minttyArgs%, %iniFile%, General, mintty_args
    IniWrite, %consoleHotkey%, %iniFile%, General, hotkey
    IniWrite, %startWithWindows%, %iniFile%, Display, start_with_windows
    IniWrite, %startHidden%, %iniFile%, Display, start_hidden
    IniWrite, %initialHeight%, %iniFile%, Display, initial_height
    IniWrite, %initialWidth%, %iniFile%, Display, initial_width
    IniWrite, %initialTrans%, %iniFile%, Display, initial_trans
    IniWrite, %autohide%, %iniFile%, Display, autohide_by_default
    IniWrite, %animationModeSlide%, %iniFile%, Display, animation_mode_slide
    IniWrite, %animationModeFade%, %iniFile%, Display, animation_mode_fade
    IniWrite, %animationStep%, %inifile%, Display, animation_step
    IniWrite, %animationTimeout%, %iniFile%, Display, animation_timeout
    CheckWindowsStartup(startWithWindows)
}

CheckWindowsStartup(enable) {
    SplitPath, A_ScriptName, , , , OutNameNoExt
    LinkFile=%A_Startup%\%OutNameNoExt%.lnk

    if !FileExist(LinkFile) {
        if (enable) {
            FileCreateShortcut, %A_ScriptFullPath%, %LinkFile%
        }
    }
    else {
        if(!enable) {
            FileDelete, %LinkFile%
        }
    }
}

;*******************************************************************************
;               Utility
;*******************************************************************************
; Gets the edge that the taskbar is docked to.  Returns:
;   "top"
;   "right"
;   "bottom"
;   "left"

VirtScreenPos(ByRef mLeft, ByRef mTop, ByRef mWidth, ByRef mHeight)
{
    Coordmode, Mouse, Screen
    SysGet, prim, MonitorPrimary
    SysGet, MonArea, MonitorWorkArea, %prim%
    mLeft := MonAreaLeft
    mTop := MonAreaTop
    mWidth := (MonAreaRight - MonAreaLeft)
    mHeight := (MonAreaBottom - MonAreaTop)
}

/*
ResizeAndCenter(w, h)
{
  ScreenX := GetScreenLeft()
  ScreenY := GetScreenTop()
  ScreenWidth := GetScreenWidth()
  ScreenHeight := GetScreenHeight()

  WinMove A,,ScreenX + (ScreenWidth/2)-(w/2),ScreenY + (ScreenHeight/2)-(h/2),w,h
}
*/
