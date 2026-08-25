#Requires -Modules ActiveDirectory

<#
.SYNOPSIS
    Crea la estructura de unidades organizativas del laboratorio IZANLAB.
.DESCRIPTION
    Script idempotente: comprueba cada OU antes de crearla y activa la
    protección contra eliminación accidental.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$domainDn = 'DC=izanlab,DC=local'

function Ensure-OrganizationalUnit {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Path
    )

    $distinguishedName = "OU=$Name,$Path"
    $existingOu = Get-ADOrganizationalUnit -Identity $distinguishedName -ErrorAction SilentlyContinue

    if ($null -eq $existingOu) {
        New-ADOrganizationalUnit `
            -Name $Name `
            -Path $Path `
            -ProtectedFromAccidentalDeletion $true

        Write-Host "[CREADA] $distinguishedName" -ForegroundColor Green
    }
    else {
        Set-ADOrganizationalUnit `
            -Identity $distinguishedName `
            -ProtectedFromAccidentalDeletion $true

        Write-Host "[EXISTE] $distinguishedName" -ForegroundColor Yellow
    }
}

Import-Module ActiveDirectory

Ensure-OrganizationalUnit -Name 'IZANLAB' -Path $domainDn
$labOu = "OU=IZANLAB,$domainDn"

Ensure-OrganizationalUnit -Name 'Usuarios' -Path $labOu
Ensure-OrganizationalUnit -Name 'Equipos' -Path $labOu
Ensure-OrganizationalUnit -Name 'Grupos' -Path $labOu
Ensure-OrganizationalUnit -Name 'Cuentas de servicio' -Path $labOu

$usersOu = "OU=Usuarios,$labOu"
Ensure-OrganizationalUnit -Name 'Direccion' -Path $usersOu
Ensure-OrganizationalUnit -Name 'Recursos Humanos' -Path $usersOu
Ensure-OrganizationalUnit -Name 'Finanzas' -Path $usersOu
Ensure-OrganizationalUnit -Name 'Sistemas' -Path $usersOu

$computersOu = "OU=Equipos,$labOu"
Ensure-OrganizationalUnit -Name 'Servidores' -Path $computersOu
Ensure-OrganizationalUnit -Name 'Puestos de trabajo' -Path $computersOu

Write-Host "`nEstructura de OU resultante:" -ForegroundColor Cyan
Get-ADOrganizationalUnit -Filter * |
    Select-Object Name, DistinguishedName |
    Sort-Object DistinguishedName |
    Format-Table -AutoSize
