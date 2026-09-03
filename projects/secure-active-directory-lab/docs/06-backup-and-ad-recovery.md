# Hito 06 — Backup y recuperación de Active Directory

## Objetivo

Implantar y validar una estrategia básica de recuperación para el controlador de dominio `DC01`, combinando una copia del estado del sistema con Windows Server Backup y la recuperación granular de objetos mediante la Papelera de reciclaje de Active Directory.

## Entorno

- Dominio: `izanlab.local`
- Controlador de dominio: `DC01`
- Disco del sistema: disco 0, 50 GB
- Disco dedicado a copias: disco 1, 30 GB
- Volumen de copias: `E:` / `BACKUP-DC01` / NTFS
- Hipervisor: Oracle VirtualBox

## Preparación del destino

Se añadió a `DC01` un segundo disco virtual de 30 GB. Después se inicializó como GPT, se creó una partición NTFS usando toda su capacidad y se asignó la etiqueta `BACKUP-DC01` y la letra `E:`.

```powershell
$Disk = Get-Disk -Number 1
Initialize-Disk -Number $Disk.Number -PartitionStyle GPT
$Partition = New-Partition -DiskNumber 1 -UseMaximumSize -AssignDriveLetter
Format-Volume -Partition $Partition -FileSystem NTFS -NewFileSystemLabel "BACKUP-DC01" -Confirm:$false
```

## Instalación de Windows Server Backup

```powershell
Install-WindowsFeature -Name Windows-Server-Backup -IncludeManagementTools
```

La característica quedó en estado `Installed`.

## Incidencia y diagnóstico VSS

El primer intento de copia del estado del sistema terminó con el código `0x807800C5`: Windows no podía preparar la imagen de uno de los volúmenes incluidos. Los escritores VSS aparecían estables y el volumen `E:` estaba sano. La revisión de volúmenes mostró que la partición **Reservado para el sistema** tenía 549 MB y poco espacio libre.

Para ofrecer almacenamiento de instantáneas a esa partición se le asignó temporalmente `S:` y se creó una asociación VSS alojada en `E:`:

```powershell
Set-Partition -DiskNumber 0 -PartitionNumber 1 -NewDriveLetter S
vssadmin add shadowstorage /for=S: /on=E: /maxsize=1GB
```

Tras completar correctamente el backup, se retiró la letra temporal. La asociación VSS permanece vinculada por GUID de volumen:

```powershell
Remove-PartitionAccessPath -DiskNumber 0 -PartitionNumber 1 -AccessPath "S:\"
```

## Copia del estado del sistema

```powershell
wbadmin start systemstatebackup -backuptarget:E: -quiet
wbadmin get versions -backuptarget:E:
```

La copia terminó correctamente. El catálogo mostró dos versiones recuperables, ambas con soporte para `Volúmenes, Archivos, Aplicaciones, Estado del sistema`.

## Recuperación granular con AD Recycle Bin

Se habilitó la Papelera de reciclaje de Active Directory para todo el bosque. Esta operación es irreversible.

```powershell
Enable-ADOptionalFeature `
    -Identity "Recycle Bin Feature" `
    -Scope ForestOrConfigurationSet `
    -Target "izanlab.local" `
    -Confirm:$false
```

Se creó una cuenta deshabilitada de prueba, `restore.test`, en `OU=Usuarios,OU=IZANLAB`, con departamento `Sistemas` y pertenencia a `GG_Sistemas`. Antes de eliminarla se registraron sus identificadores:

- ObjectGUID: `25809837-c212-45aa-852f-49285e350774`
- SID: terminado en `-1122`

Después de eliminarla, se localizó entre los objetos eliminados y se restauró por GUID:

```powershell
Restore-ADObject -Identity "25809837-c212-45aa-852f-49285e350774"
```

La validación confirmó que se conservaron:

- el mismo ObjectGUID y SID;
- la OU original;
- el departamento y la descripción;
- el estado deshabilitado;
- la pertenencia a `GG_Sistemas`.

Al finalizar la prueba se retiró la cuenta del grupo y se eliminó de nuevo para dejar limpio el entorno.

## Alcance de la prueba de recuperación

Se ejecutó una restauración granular segura mediante AD Recycle Bin. No se realizó una restauración completa del estado del sistema porque `DC01` es el único controlador del dominio del laboratorio. Una recuperación completa requeriría iniciar en DSRM, seleccionar una versión válida con `wbadmin` y asumir una interrupción del servicio.

Procedimiento documentado para una contingencia real:

1. Confirmar el catálogo con `wbadmin get versions -backuptarget:E:`.
2. Reiniciar el controlador en Directory Services Repair Mode (DSRM).
3. Iniciar sesión con la contraseña DSRM.
4. Ejecutar `wbadmin start systemstaterecovery -version:<versión> -backuptarget:E:`.
5. Reiniciar y validar AD DS, DNS, SYSVOL, replicación y eventos.

## Resultado

- Disco de backup separado y sano: **validado**.
- Windows Server Backup: **instalado**.
- Copia del estado del sistema: **completada**.
- Catálogo y versiones recuperables: **validados**.
- Incidencia VSS: **diagnosticada y corregida**.
- AD Recycle Bin: **habilitada en el bosque**.
- Eliminación y recuperación de usuario: **validada**.
- Conservación de identidad, atributos y grupos: **validada**.
- Snapshot final: `06-Backup-y-recuperacion-AD-validados`.

## Consideraciones operativas

- El volumen `E:` terminó con aproximadamente 15,2 GB libres de 29,98 GB.
- Debe revisarse periódicamente el espacio y el catálogo de versiones.
- El disco virtual de backup protege frente a errores lógicos del sistema, pero no sustituye una copia externa u offline frente a fallo del host o ransomware.
- AD Recycle Bin agiliza la recuperación de objetos, pero no sustituye el backup del estado del sistema.
