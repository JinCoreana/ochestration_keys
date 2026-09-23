param(
    [ValidateSet("Show", "Hide", "Display")]
    [string]$Mode = "Show"
)

$ErrorActionPreference = "Stop"
$indicatorPath = $MyInvocation.MyCommand.Path

function Get-IndicatorProcesses {
    Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" |
        Where-Object { $_.CommandLine -and $_.CommandLine.Contains("mute_indicator.ps1") -and $_.CommandLine.Contains("-Mode Display") }
}

if ($Mode -eq "Hide") {
    Get-IndicatorProcesses | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    exit 0
}

if ($Mode -eq "Show") {
    if (-not (Get-IndicatorProcesses)) {
        $arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$indicatorPath`" -Mode Display"
        Start-Process powershell.exe -ArgumentList $arguments -WindowStyle Hidden
    }
    exit 0
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
$form.ShowInTaskbar = $false
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::FromArgb(170, 35, 35)
$form.Size = New-Object System.Drawing.Size(96, 34)

$workArea = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$form.Location = New-Object System.Drawing.Point(($workArea.Right - $form.Width - 16), ($workArea.Bottom - $form.Height - 16))

$label = New-Object System.Windows.Forms.Label
$label.Text = "MIC OFF"
$label.ForeColor = [System.Drawing.Color]::White
$label.BackColor = [System.Drawing.Color]::Transparent
$label.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$label.Dock = [System.Windows.Forms.DockStyle]::Fill
$form.Controls.Add($label)

[System.Windows.Forms.Application]::Run($form)
