#Requires -Modules ActiveDirectory

<#
.SYNOPSIS
    Implementa grupos locales, anidamiento AGDLP, carpetas, ACL NTFS y SMB.
.DESCRIPTION
    Diseñado para el laboratorio aislado izanlab.local. Utiliza SID para las
    cuentas integradas y aplica permisos explícitos sin herencia.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Import-Module ActiveDirectory

$groupsOu = 'OU=Grupos,OU=IZANLAB,DC=izanlab,DC=local'
$basePath = 'C:\IZANLAB-Datos'

$resources = @(
    @{ Folder='Direccion'; Global='GG_Direccion'; Local='DL_Direccion_Modificar'; Ntfs='M'; Share='Change' },
    @{ Folder='RRHH'; Global='GG_RRHH'; Local='DL_RRHH_Modificar'; Ntfs='M'; Share='Change' },
    @{ Folder='Finanzas'; Global='GG_Finanzas'; Local='DL_Finanzas_Modificar'; Ntfs='M'; Share='Change' },
    @{ Folder='Sistemas'; Global='GG_Sistemas'; Local='DL_Sistemas_Modificar'; Ntfs='M'; Share='Change' }
)

foreach ($resource in $resources) {
    if (-not (Get-ADGroup -Filter "SamAccountName -eq '$($resource.Local)'")) {
        New-ADGroup -Name $resource.Local -SamAccountName $resource.Local `
            -GroupCategory Security -GroupScope DomainLocal -Path $groupsOu `
            -Description "Permiso de modificacion sobre $($resource.Folder)"
    }
    Add-ADGroupMember -Identity $resource.Local -Members $resource.Global
}

$sharedLocal = 'DL_Compartido_Lectura'
if (-not (Get-ADGroup -Filter "SamAccountName -eq '$sharedLocal'")) {
    New-ADGroup -Name $sharedLocal -SamAccountName $sharedLocal `
        -GroupCategory Security -GroupScope DomainLocal -Path $groupsOu `
        -Description 'Permiso de lectura sobre la carpeta Compartido'
}

Add-ADGroupMember -Identity $sharedLocal `
    -Members ($resources.Global)

$resources += @{
    Folder='Compartido'
    Global=$null
    Local=$sharedLocal
    Ntfs='RX'
    Share='Read'
}

New-Item -Path $basePath -ItemType Directory -Force | Out-Null

$administrators = (
    New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')
).Translate([System.Security.Principal.NTAccount]).Value

foreach ($resource in $resources) {
    $path = Join-Path $basePath $resource.Folder
    $groupSid = (Get-ADGroup $resource.Local).SID.Value
    $domainGroup = "IZANLAB\$($resource.Local)"

    New-Item -Path $path -ItemType Directory -Force | Out-Null

    & icacls.exe $path /inheritance:r | Out-Null
    & icacls.exe $path /grant:r `
        '*S-1-5-18:(OI)(CI)(F)' `
        '*S-1-5-32-544:(OI)(CI)(F)' `
        "*$($groupSid):(OI)(CI)($($resource.Ntfs))" | Out-Null

    if (-not (Get-SmbShare -Name $resource.Folder -ErrorAction SilentlyContinue)) {
        if ($resource.Share -eq 'Change') {
            New-SmbShare -Name $resource.Folder -Path $path `
                -FullAccess $administrators -ChangeAccess $domainGroup `
                -FolderEnumerationMode AccessBased | Out-Null
        }
        else {
            New-SmbShare -Name $resource.Folder -Path $path `
                -FullAccess $administrators -ReadAccess $domainGroup `
                -FolderEnumerationMode AccessBased | Out-Null
        }
    }

    Write-Host "[CONFIGURADO] $($resource.Folder) -> $($resource.Local)" `
        -ForegroundColor Green
}

$testFiles = @{
    Direccion = 'Documento confidencial del departamento de Direccion.'
    RRHH = 'Documento confidencial del departamento de Recursos Humanos.'
    Finanzas = 'Documento confidencial del departamento de Finanzas.'
    Sistemas = 'Documento confidencial del departamento de Sistemas.'
    Compartido = 'Documento corporativo disponible en modo lectura.'
}

foreach ($entry in $testFiles.GetEnumerator()) {
    $fileName = if ($entry.Key -eq 'Compartido') {
        'Aviso-General.txt'
    }
    else {
        "Documento-$($entry.Key).txt"
    }
    Set-Content -Path (Join-Path (Join-Path $basePath $entry.Key) $fileName) `
        -Value $entry.Value
}

Get-SmbShare | Where-Object Name -in $resources.Folder |
    Select-Object Name, Path, FolderEnumerationMode |
    Format-Table -AutoSize
