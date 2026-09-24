; master_hotkeys.ahk
; Register master hotkeys F13-F24. Only task names are managed here;
; the shared/ logic does not know which physical keys invoke them.
;
; Every task uses the active Windows system/input language.

#Requires AutoHotkey v2.0
#SingleInstance Force
#Include tasks\layer_switch.ahk
#Include tasks\knob_highlight_copy.ahk
#Include tasks\screenshot_capture.ahk
#Include tasks\text_refine.ahk
#Include shared\popup_indicator.ahk

; ---- Interactive screenshot to clipboard ----
F13:: CaptureRegionToClipboard()

; ---- Production deployment: a two-second hold is required ----
F14:: RunProduction()

; ---- UAT deployment ----
F15:: RunTask("deploy_uat", "", true)

; ---- Highlighted text refinement ----
F16:: RefineSelection()

; ---- QA automation ----
F17:: RunTask("qa_playwright_run")

; ---- Media mute: the local OS action is language-independent ----
F18:: RunMediaMute()

; ---- Code analysis ----
F19:: RunTask("big_o_analysis")

; ---- Client communication ----
F20:: RunTask("client_comm_template")

; ---- Merge request review ----
F21:: RunTask("mr_diff_review", "", true)

; ---- Jira multi-agent orchestration ----
F22:: RunTask("jira_multi_agent")

; ---- Local development bootstrap ----
F23:: RunTask("local_dev_bootstrap")

; ---- Dynatrace root-cause analysis ----
F24:: RunTask("dynatrace_rca")

RunProduction() {
    KeyWait("F14", "T2")
    if (GetKeyState("F14", "P") = 0)
        return
    RunTask("deploy_prod", "", true, true)
}

RunMediaMute() {
    ToggleMicrophone()
}
