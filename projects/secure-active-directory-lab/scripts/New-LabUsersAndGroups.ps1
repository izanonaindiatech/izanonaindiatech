#Requires -Modules ActiveDirectory

<#
.SYNOPSIS
    Crea usuarios ficticios y grupos globales para el laboratorio IZANLAB.
.NOTES
    La contraseña se solicita de forma interactiva y nunca se almacena en el script.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Import-Module ActiveDirectory

$domainDn = 'DC=izanlab,DC=local'
$usersOu = "OU=Usuarios,OU=IZANLAB,$domainDn"
$groupsOu = "OU=Grupos,OU=IZANLAB,$domainDn"
$temporaryPassword = Read-Host 'Contraseña temporal para las cuentas nuevas' -AsSecureString

$groups = @(
    @{ Name = 'GG_Direccion'; Description = 'Usuarios del departamento de Direccion' },
    @{ Name = 'GG_RRHH'; Description = 'Usuarios del departamento de Recursos Humanos' },
    @{ Name = 'GG_Finanzas'; Description = 'Usuarios del departamento de Finanzas' },
    @{ Name = 'GG_Sistemas'; Description = 'Usuarios del departamento de Sistemas' }
)

foreach ($group in $groups) {
    if (-not (Get-ADGroup -Filter "SamAccountName -eq '$($group.Name)'")) {
        New-ADGroup -Name $group.Name -SamAccountName $group.Name `
            -GroupCategory Security -GroupScope Global -Path $groupsOu `
            -Description $group.Description
        Write-Host "[GRUPO CREADO] $($group.Name)" -ForegroundColor Green
    }
    else {
        Write-Host "[GRUPO EXISTENTE] $($group.Name)" -ForegroundColor Yellow
    }
}

$users = @(
    @{ Given='Laura'; Surname='Martin'; Sam='laura.martin'; Department='Direccion'; Ou='Direccion'; Group='GG_Direccion' },
    @{ Given='Carlos'; Surname='Vega'; Sam='carlos.vega'; Department='Direccion'; Ou='Direccion'; Group='GG_Direccion' },
    @{ Given='Ana'; Surname='Lopez'; Sam='ana.lopez'; Department='Recursos Humanos'; Ou='Recursos Humanos'; Group='GG_RRHH' },
    @{ Given='David'; Surname='Ruiz'; Sam='david.ruiz'; Department='Recursos Humanos'; Ou='Recursos Humanos'; Group='GG_RRHH' },
    @{ Given='Marta'; Surname='Gil'; Sam='marta.gil'; Department='Finanzas'; Ou='Finanzas'; Group='GG_Finanzas' },
    @{ Given='Pablo'; Surname='Sanz'; Sam='pablo.sanz'; Department='Finanzas'; Ou='Finanzas'; Group='GG_Finanzas' },
    @{ Given='Elena'; Surname='Torres'; Sam='elena.torres'; Department='Sistemas'; Ou='Sistemas'; Group='GG_Sistemas' },
    @{ Given='Sergio'; Surname='Mora'; Sam='sergio.mora'; Department='Sistemas'; Ou='Sistemas'; Group='GG_Sistemas' }
)

foreach ($user in $users) {
    $existingUser = Get-ADUser -Filter "SamAccountName -eq '$($user.Sam)'"

    if (-not $existingUser) {
        New-ADUser -Name "$($user.Given) $($user.Surname)" `
            -GivenName $user.Given -Surname $user.Surname `
            -DisplayName "$($user.Given) $($user.Surname)" `
            -SamAccountName $user.Sam `
            -UserPrincipalName "$($user.Sam)@izanlab.local" `
            -Department $user.Department `
            -Path "OU=$($user.Ou),$usersOu" `
            -AccountPassword $temporaryPassword -Enabled $true `
            -ChangePasswordAtLogon $true
        Write-Host "[USUARIO CREADO] $($user.Sam)" -ForegroundColor Green
    }
    else {
        Write-Host "[USUARIO EXISTENTE] $($user.Sam)" -ForegroundColor Yellow
    }

    Add-ADGroupMember -Identity $user.Group -Members $user.Sam
}

Get-ADGroup -Filter 'Name -like "GG_*"' |
    Sort-Object Name |
    ForEach-Object {
        Write-Host "`n$($_.Name)" -ForegroundColor Cyan
        Get-ADGroupMember $_ | Select-Object Name, SamAccountName |
            Format-Table -AutoSize
    }
