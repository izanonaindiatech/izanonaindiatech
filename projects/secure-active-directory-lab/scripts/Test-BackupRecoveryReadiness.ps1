#requires -RunAsAdministrator

Import-Module ActiveDirectory

Write-Host "=== Volumen de backup ===" -ForegroundColor Cyan
Get-Volume -DriveLetter E |
    Select-Object DriveLetter, FileSystemLabel, FileSystem,
        HealthStatus, OperationalStatus,
        @{Name="FreeGB";Expression={[math]::Round($_.SizeRemaining / 1GB, 2)}},
        @{Name="SizeGB";Expression={[math]::Round($_.Size / 1GB, 2)}} |
    Format-Table -AutoSize

Write-Host "=== Caracteristica Windows Server Backup ===" -ForegroundColor Cyan
Get-WindowsFeature -Name Windows-Server-Backup |
    Select-Object DisplayName, Name, InstallState |
    Format-Table -AutoSize

Write-Host "=== Papelera de Active Directory ===" -ForegroundColor Cyan
Get-ADOptionalFeature -Identity "Recycle Bin Feature" |
    Select-Object Name, EnabledScopes |
    Format-List

Write-Host "=== Catalogo de copias ===" -ForegroundColor Cyan
wbadmin get versions -backuptarget:E:
