# 현재 포커스된 앱에서 커서 기준 앞/뒤로 하이라이트 영역을 확장하거나,
# 하이라이트된 텍스트를 클립보드로 복사하고 반환합니다.
# 사용법: powershell -File text_highlighter.ps1 -Extend forward|backward
#         powershell -File text_highlighter.ps1 -Copy

param(
    [ValidateSet("forward","backward")]
    [string]$Extend,
    [switch]$Copy
)

Add-Type -AssemblyName System.Windows.Forms

if ($Extend) {
    if ($Extend -eq "forward") {
        [System.Windows.Forms.SendKeys]::SendWait("+{RIGHT}")
    } else {
        [System.Windows.Forms.SendKeys]::SendWait("+{LEFT}")
    }
} elseif ($Copy) {
    [System.Windows.Forms.SendKeys]::SendWait("^c")
    Start-Sleep -Milliseconds 150
    $text = Get-Clipboard
    Write-Output $text
}
