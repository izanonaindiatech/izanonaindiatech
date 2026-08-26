## Hito: control de acceso AGDLP y recursos SMB

Se ha implementado un modelo de autorización basado en roles mediante **AGDLP** (`Accounts -> Global groups -> Domain Local groups -> Permissions`). El laboratorio incorpora usuarios por departamento, grupos de seguridad globales y locales, recursos SMB y permisos NTFS de mínimo privilegio.

Validaciones realizadas desde `CL01`:

- Acceso de modificación únicamente al recurso del departamento propio.
- Acceso denegado a los recursos de otros departamentos.
- Lectura permitida y escritura denegada en el recurso corporativo compartido.
- Diagnóstico y corrección de una ACL NTFS incorrecta sin asignar permisos directos a usuarios.

Documentación: [`docs/04-agdlp-file-permissions.md`](docs/04-agdlp-file-permissions.md)

Scripts:

- [`scripts/New-LabUsersAndGroups.ps1`](scripts/New-LabUsersAndGroups.ps1)
- [`scripts/New-AGDLPFileShares.ps1`](scripts/New-AGDLPFileShares.ps1)
