; Reusable popup indicators and native microphone toggle.

muteIndicatorGui := 0
statusModalGui := 0

ToggleMicrophone() {
    global muteIndicatorGui
    enumerator := ComObject("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")
    device := 0
    result := ComCall(4, enumerator, "int", 1, "int", 2, "ptr*", &device)
    if (result != 0)
        throw Error("Could not find the default communications microphone.", -1, result)

    endpointIid := Buffer(16, 0)
    DllCall("ole32\CLSIDFromString", "wstr", "{5CDF2C82-841E-4546-9722-0CF74078229A}", "ptr", endpointIid)
    endpoint := 0
    result := ComCall(3, device, "ptr", endpointIid, "uint", 23, "ptr", 0, "ptr*", &endpoint)
    ObjRelease(device)
    if (result != 0)
        throw Error("Could not activate the microphone endpoint.", -1, result)

    muted := 0
    result := ComCall(15, endpoint, "int*", &muted)
    if (result = 0)
        result := ComCall(14, endpoint, "int", muted ? 0 : 1, "ptr", 0)
    ObjRelease(endpoint)
    if (result != 0)
        throw Error("Could not change the microphone mute state.", -1, result)

    if (muted)
        HideMuteIndicator()
    else
        ShowMuteIndicator()
}

ShowMuteIndicator() {
    global muteIndicatorGui
    if IsObject(muteIndicatorGui)
        return
    MonitorGetWorkArea(, &workLeft, &workTop, &workRight, &workBottom)
    muteIndicatorGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "Mic Status")
    muteIndicatorGui.BackColor := "8B1E1E"
    muteIndicatorGui.SetFont("s10 Bold", "Segoe UI")
    muteIndicatorGui.Add("Text", "w82 h28 Center cFFFFFF", "MIC OFF")
    muteIndicatorGui.Show("x" . (workLeft + 16) . " y" . (workBottom - 48) . " NA")
}

HideMuteIndicator() {
    global muteIndicatorGui
    if IsObject(muteIndicatorGui) {
        muteIndicatorGui.Destroy()
        muteIndicatorGui := 0
    }
}

ShowStatusModal(message, duration := 1000) {
    global statusModalGui
    if IsObject(statusModalGui)
        statusModalGui.Destroy()
    MonitorGetWorkArea(, &workLeft, &workTop, &workRight, &workBottom)
    statusModalGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "Status")
    statusModalGui.BackColor := "8B1E1E"
    statusModalGui.SetFont("s10 Bold", "Segoe UI")
    statusModalGui.Add("Text", "w320 h34 Center cFFFFFF", message)
    statusModalGui.Show("x" . (workLeft + 16) . " y" . (workBottom - 58) . " NA")
    SetTimer(HideStatusModal, -duration)
}

HideStatusModal() {
    global statusModalGui
    if IsObject(statusModalGui) {
        statusModalGui.Destroy()
        statusModalGui := 0
    }
}
