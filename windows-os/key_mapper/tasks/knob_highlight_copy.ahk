; knob_highlight_copy.ahk
; Dedicated dial controls for Shift+F13 through Shift+F18.
;
; Speed tuning:
; - DIAL_SELECTION_STEP: Starting movement per dial step.
;   Fast consecutive turns accelerate automatically up to DIAL_MAX_SELECTION_STEP.
; - DIAL_DEBOUNCE_MS: Minimum interval in milliseconds before the same input is accepted again.
;   Lower values are faster but may allow noise; higher values are more stable but may
;   ignore some rapid rotation inputs.
; - DIAL_ACCELERATION_WINDOW_MS: Consecutive input window used for acceleration.
;
; Examples:
;   Faster base: DIAL_SELECTION_STEP := 2
;   More precise: DIAL_SELECTION_STEP := 1, DIAL_MAX_SELECTION_STEP := 4

DIAL_SELECTION_STEP := 1
DIAL_MAX_SELECTION_STEP := 50
DIAL_ACCELERATION_WINDOW_MS := 180
DIAL_DEBOUNCE_MS := 10

#MaxThreads 255
#MaxThreadsPerHotkey 255

; Knob 1: left=F13, click=F14, right=F15
+F13:: {
    if (DialReady("knob1-left"))
        AdjustSelection("Left")
}
+F14:: {
    if (DialReady("knob1-click"))
        CopySelection()
}
+F15:: {
    if (DialReady("knob1-right"))
        AdjustSelection("Right")
}

; Knob 2: left=F16 (IDE), right=F17 (terminal), click=F18 (browser)
+F16:: FocusWindow("knob2-left", "ide")
+F17:: FocusWindow("knob2-right", "terminal")
+F18:: FocusWindow("knob2-click", "browser")

DialReady(name) {
    global DIAL_DEBOUNCE_MS
    static lastTriggered := Map()
    now := A_TickCount
    if (lastTriggered.Has(name) && now - lastTriggered[name] < DIAL_DEBOUNCE_MS)
        return false
    lastTriggered[name] := now
    return true
}

AdjustSelection(direction) {
    global DIAL_SELECTION_STEP, DIAL_MAX_SELECTION_STEP, DIAL_ACCELERATION_WINDOW_MS
    static lastDirection := ""
    static lastTick := 0
    static currentStep := DIAL_SELECTION_STEP
    now := A_TickCount
    elapsed := now - lastTick

    if (direction != lastDirection || elapsed > DIAL_ACCELERATION_WINDOW_MS)
        currentStep := DIAL_SELECTION_STEP
    else
        currentStep := Min(currentStep + 1, DIAL_MAX_SELECTION_STEP)

    SendInput("{Blind}+{" . direction . " " . currentStep . "}")
    lastDirection := direction
    lastTick := now
}

FocusWindow(name, target) {
    if (!DialReady(name))
        return
    scriptPath := A_ScriptDir . "\..\scripts\window_manager.ps1"
    command := 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' . scriptPath . '" -Focus ' . target
    Run(command, , "Hide")
}

CopySelection() {
    shiftWasDown := GetKeyState("Shift", "P")
    if (shiftWasDown)
        SendInput("{Shift up}")
    SendInput("^c")
    SendInput("{Left}")
    if (shiftWasDown)
        SendInput("{Shift down}")
}
