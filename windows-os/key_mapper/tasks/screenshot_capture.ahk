; Interactive region screenshot task.
; Win+Shift+S opens Windows Snipping Tool. The selected image is copied to the clipboard.

screenshotLaunchInProgress := false

CaptureRegionToClipboard() {
    global screenshotLaunchInProgress
    if (screenshotLaunchInProgress)
        return
    screenshotLaunchInProgress := true
    try {
        SendInput("#+s")
    } finally {
        SetTimer(ResetScreenshotLaunch, -300)
    }
}

ResetScreenshotLaunch() {
    global screenshotLaunchInProgress
    screenshotLaunchInProgress := false
}
