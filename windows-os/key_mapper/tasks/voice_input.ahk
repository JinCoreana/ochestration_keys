; Voice input task helper.
; Windows Voice Typing uses the active Windows input language.

RunVoiceInput() {
    ; Win+H toggles Windows Voice Typing without touching existing dictated text.
    ToolTip("Microsoft Voice Typing")
    SendInput("#h")
    SetTimer(() => ToolTip(), -2000)
}
