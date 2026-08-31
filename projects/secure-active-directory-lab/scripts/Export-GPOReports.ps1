[CmdletBinding()]
param(
    [string]$OutputPath = "C:\IZANLAB-Evidencias-GPO"
)

$ErrorActionPreference = "Stop"

Import-Module GroupPolicy

New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null

$GPOs = @(
    "GPO-CL01-Security-Baseline",
    "GPO-DC01-Audit-Policy"
)

foreach ($GPO in $GPOs) {
    $Destino = Join-Path $OutputPath "$GPO.html"

    Get-GPOReport `
        -Name $GPO `
        -ReportType Html `
        -Path $Destino

    Write-Host "[OK] $Destino" -ForegroundColor Green
}

Get-ChildItem -Path $OutputPath -Filter "*.html" |
    Select-Object Name, Length, LastWriteTime |
    Format-Table -AutoSize
