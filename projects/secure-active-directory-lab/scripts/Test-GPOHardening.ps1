[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host "Equipo" -ForegroundColor Cyan
hostname

Write-Host "`nGPO aplicadas" -ForegroundColor Cyan
gpresult /scope computer /r

Write-Host "`nPerfiles de firewall efectivos" -ForegroundColor Cyan
Get-NetFirewallProfile -PolicyStore ActiveStore |
    Select-Object Name,
                  Enabled,
                  DefaultInboundAction,
                  DefaultOutboundAction,
                  LogBlocked,
                  LogAllowed,
                  LogMaxSizeKilobytes,
                  LogFileName |
    Format-Table -AutoSize

Write-Host "`nPolitica de auditoria efectiva" -ForegroundColor Cyan
auditpol /get /category:*

$Desde = (Get-Date).AddHours(-1)

Write-Host "`nEventos de seguridad recientes" -ForegroundColor Cyan
Get-WinEvent -FilterHashtable @{
    LogName   = "Security"
    Id        = 4624, 4625, 4634, 4672, 4688, 4689, 4738
    StartTime = $Desde
} -ErrorAction SilentlyContinue |
    Select-Object -First 25 TimeCreated, Id, ProviderName |
    Format-Table -AutoSize
