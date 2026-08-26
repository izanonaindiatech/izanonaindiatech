# Control de acceso AGDLP y recursos compartidos SMB

## Objetivo

Implementar un modelo de autorización basado en roles para el dominio `izanlab.local`, evitando asignar permisos directamente a usuarios. El laboratorio utiliza el modelo **AGDLP**:

```text
Accounts -> Global groups -> Domain Local groups -> Permissions
```

## Entorno

| Equipo | Dirección | Función |
|---|---:|---|
| DC01 | 10.10.10.10/24 | Active Directory, DNS y recursos SMB |
| CL01 | 10.10.10.20/24 | Cliente Windows 10 unido al dominio |

En un entorno de producción se recomienda separar el controlador de dominio y el servidor de archivos. En este laboratorio ambos servicios se alojan en `DC01` para reducir el consumo de recursos.

## Usuarios y grupos globales

Se crearon ocho cuentas ficticias distribuidas en cuatro departamentos:

| Departamento | Usuarios | Grupo global |
|---|---|---|
| Dirección | Laura Martín, Carlos Vega | `GG_Direccion` |
| Recursos Humanos | Ana López, David Ruiz | `GG_RRHH` |
| Finanzas | Marta Gil, Pablo Sanz | `GG_Finanzas` |
| Sistemas | Elena Torres, Sergio Mora | `GG_Sistemas` |

Las cuentas se colocaron en sus unidades organizativas departamentales y se incorporaron al grupo global correspondiente.

## Grupos locales y anidamiento

| Grupo global | Grupo local de dominio | Acceso resultante |
|---|---|---|
| `GG_Direccion` | `DL_Direccion_Modificar` | Modificar Dirección |
| `GG_RRHH` | `DL_RRHH_Modificar` | Modificar RRHH |
| `GG_Finanzas` | `DL_Finanzas_Modificar` | Modificar Finanzas |
| `GG_Sistemas` | `DL_Sistemas_Modificar` | Modificar Sistemas |
| Todos los `GG_` | `DL_Compartido_Lectura` | Leer Compartido |

Los permisos se asignaron exclusivamente a grupos `DL_`, nunca directamente a usuarios ni a grupos globales.

## Recursos compartidos

```text
C:\IZANLAB-Datos
├── Direccion
├── RRHH
├── Finanzas
├── Sistemas
└── Compartido
```

Los recursos departamentales conceden `Change` en SMB y `Modify` en NTFS a su grupo local. `Compartido` concede `Read` en SMB y `ReadAndExecute` en NTFS. `SYSTEM` y el grupo integrado de administradores conservan control total.

## Validación funcional

### Laura Martín — Dirección

- Identidad validada como `izanlab\laura.martin`.
- Pertenencia a `GG_Direccion`, `DL_Direccion_Modificar` y `DL_Compartido_Lectura`.
- Lectura, creación y modificación permitidas en `\\DC01\Direccion`.
- Acceso denegado a `\\DC01\RRHH`.
- Lectura permitida y escritura denegada en `\\DC01\Compartido`.

### Ana López — Recursos Humanos

- Identidad validada como `izanlab\ana.lopez`.
- Pertenencia a `GG_RRHH`, `DL_RRHH_Modificar` y `DL_Compartido_Lectura`.
- Lectura, creación y modificación permitidas en `\\DC01\RRHH`.
- Acceso denegado a `\\DC01\Direccion`.
- Lectura permitida y escritura denegada en `\\DC01\Compartido`.

## Incidencia y resolución

Durante las pruebas, Laura podía leer la carpeta de Dirección pero no escribir. El diagnóstico se realizó por capas:

1. Se verificó que `GG_Direccion` estaba anidado en `DL_Direccion_Modificar`.
2. Se confirmó que el token de Laura contenía el grupo local habilitado.
3. Se comprobó que SMB concedía `Change` al grupo correcto.
4. `Get-Acl` e `icacls` mostraron que la entrada del grupo había desaparecido de la ACL NTFS y que la carpeta estaba heredando permisos.
5. Se deshabilitó la herencia y se reaplicaron permisos explícitos mediante SID.
6. La prueba posterior confirmó escritura en Dirección y denegación en Compartido.

La incidencia demuestra la diferencia entre autenticación, pertenencia a grupos, autorización SMB y autorización NTFS. El acceso efectivo es la combinación más restrictiva de las dos capas de permisos.

## Riesgos mitigados

- Asignación directa y difícil de auditar de permisos a usuarios.
- Acceso entre departamentos sin necesidad empresarial.
- Escritura no autorizada en documentación corporativa común.
- Dependencia de nombres localizados de cuentas integradas.
- Propagación accidental de permisos heredados.

## Evidencias

Las capturas incluidas en `evidence/` muestran la creación de cuentas, los grupos globales y locales, el anidamiento, los permisos SMB/NTFS, el diagnóstico de la incidencia y las pruebas positivas y negativas desde `CL01`.

## Automatización

- [`New-LabUsersAndGroups.ps1`](../scripts/New-LabUsersAndGroups.ps1)
- [`New-AGDLPFileShares.ps1`](../scripts/New-AGDLPFileShares.ps1)

## Siguiente paso

Aplicar GPO de contraseña y bloqueo, restricciones de usuario, configuración de auditoría y revisión de eventos de seguridad.
