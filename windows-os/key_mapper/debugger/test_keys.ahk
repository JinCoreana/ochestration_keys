; test_keys.ahk
; Debugger for every physical F13-F24 key and modifier combination.
; Run this file by itself without changing master_hotkeys.ahk.
;
; Each event records Shift, Alt, and Ctrl state in debugger/logs/key_input.log.
#Requires AutoHotkey v2.0
#SingleInstance Force

*F13:: TrackKey("F13")
*F14:: TrackKey("F14")
*F15:: TrackKey("F15")
*F16:: TrackKey("F16")
*F17:: TrackKey("F17")
*F18:: TrackKey("F18")
*F19:: TrackKey("F19")
*F20:: TrackKey("F20")
*F21:: TrackKey("F21")
*F22:: TrackKey("F22")
*F23:: TrackKey("F23")
*F24:: TrackKey("F24")

TrackKey(keyName) {
    static hitCount := 0
    hitCount += 1
    shiftText := GetKeyState("Shift", "P") ? "DOWN" : "UP"
    altText := GetKeyState("Alt", "P") ? "DOWN" : "UP"
    ctrlText := GetKeyState("Ctrl", "P") ? "DOWN" : "UP"
    modifiers := "Shift=" . shiftText . " Alt=" . altText . " Ctrl=" . ctrlText
    timestamp := A_Year . "-" . A_Mon . "-" . A_MDay . " " . A_Hour . ":" . A_Min . ":" . A_Sec
    fullMsg := "[" . hitCount . "] " . timestamp . " " . keyName . " (" . modifiers . ")"
    logPath := A_ScriptDir . "\logs\key_input.log"
    FileAppend(fullMsg . "`n", logPath, "UTF-8")

    ; Show a large temporary popup because ToolTip is easy to miss.
    myGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "KnobTest")
    myGui.SetFont("s16", "Segoe UI")
    myGui.Add("Text", "w400 Center", fullMsg)
    myGui.Show("y50 NoActivate")
    SetTimer(() => myGui.Destroy(), -2000)

    SoundBeep(800, 150)
}
