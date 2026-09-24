; Refine the currently highlighted text through the shared AI runner.

RefineSelection() {
    static isRunning := false
    if (isRunning)
        return
    isRunning := true
    try {
        sourceWindow := WinGetID("A")
        sourceControl := ControlGetFocus("A")
        savedClipboard := ClipboardAll()
        A_Clipboard := ""
        SendInput("^c")
        if (!ClipWait(1)) {
            A_Clipboard := savedClipboard
            SoundBeep(250, 200)
            return
        }

        exitCode := RunTask("text_refine")
        if (exitCode != 0) {
            A_Clipboard := savedClipboard
            if (exitCode = 9009)
                ToolTip("F16 refine unavailable: install Python 3.10+ and add it to PATH.")
            else if (exitCode = 429)
                ShowStatusModal("Gemini token quota exhausted", 1000)
            else
                ToolTip("F16 refine failed: check Gemini API/model settings. Original selection preserved.")
            SetTimer(() => ToolTip(), -3500)
            return
        }
        if (!RestoreInputTarget(sourceWindow, sourceControl)) {
            ToolTip("Original input field is no longer available. Refined text remains in the clipboard.")
            SetTimer(() => ToolTip(), -3500)
            return
        }
        SendInput("^v")
        Sleep(200)
        A_Clipboard := savedClipboard
    } finally {
        isRunning := false
    }
}

RestoreInputTarget(windowId, controlName) {
    windowTitle := "ahk_id " . windowId
    if (!WinExist(windowTitle))
        return false
    WinActivate(windowTitle)
    if (!WinWaitActive(windowTitle, , 2))
        return false
    if (controlName != "") {
        try ControlFocus(controlName, windowTitle)
    }
    return true
}
