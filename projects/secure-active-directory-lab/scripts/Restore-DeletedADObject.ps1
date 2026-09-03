#requires -RunAsAdministrator

param(
    [Parameter(Mandatory = $true)]
    [Guid]$ObjectGuid
)

Import-Module ActiveDirectory

$DeletedObject = Get-ADObject `
    -Identity $ObjectGuid `
    -IncludeDeletedObjects `
    -Properties isDeleted, lastKnownParent, objectSid, whenChanged

$DeletedObject |
    Select-Object Name, isDeleted, lastKnownParent, ObjectGUID, objectSid, whenChanged |
    Format-List

Restore-ADObject -Identity $DeletedObject.ObjectGUID -Confirm:$false

Write-Host "Objeto restaurado. Valide atributos, OU y grupos antes de cerrar la incidencia." -ForegroundColor Green
