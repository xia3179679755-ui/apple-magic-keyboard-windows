#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook

; Apple Magic Keyboard bottom-row layout on Windows:
; Command -> Ctrl, Control -> Win, Option remains Alt.
; Stop this script from the AutoHotkey tray menu to restore the default layout.
LWin::LCtrl
RWin::RCtrl
LCtrl::LWin
RCtrl::RWin

; Ctrl+Alt+M toggles the mapping without exiting the script.
^!m::Suspend -1
