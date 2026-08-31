[CmdletBinding()]
param(
    [string]$Identity = "test.bloqueo"
)

$ErrorActionPreference = "Stop"

Import-Module ActiveDirectory

$Desde = Get-Date
$Usuario = Get-ADUser -Identity $Identity -Properties Description
$DescripcionOriginal = $Usuario.Description

try {
    Set-ADUser -Identity $Identity -Description "Prueba temporal de auditoria GPO"
    Start-Sleep -Seconds 3
}
finally {
    if ([string]::IsNullOrWhiteSpace($DescripcionOriginal)) {
        Set-ADUser -Identity $Identity -Clear Description
    }
    else {
        Set-ADUser -Identity $Identity -Description $DescripcionOriginal
    }
}

Start-Sleep -Seconds 3

Get-WinEvent -FilterHashtable @{
    LogName   = "Security"
    Id        = 4738
    StartTime = $Desde
} |
    Where-Object { $_.Message -like "*$Identity*" } |
    Select-Object -First 1 |
    Format-List TimeCreated, Id, Message
