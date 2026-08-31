# Hito 05 — GPO, hardening y auditoría

## Objetivo

Este hito aplica una línea base de seguridad diferenciada para estaciones de trabajo y controladores de dominio del laboratorio `izanlab.local`. El diseño evita mezclar controles de endpoint con auditoría específica de Active Directory.

## Arquitectura de directivas

| GPO | Vínculo | Destino | Función |
|---|---|---|---|
| `Default Domain Policy` | Dominio | Todo el dominio | Contraseñas y bloqueo de cuentas |
| `GPO-CL01-Security-Baseline` | `OU=Puestos de trabajo,OU=Equipos,OU=IZANLAB` | CL01 | Hardening, firewall y auditoría de estación |
| `GPO-DC01-Audit-Policy` | `OU=Domain Controllers` | DC01 | Auditoría de cuentas, directorio y Kerberos |

## Política de contraseñas y bloqueo

- Longitud mínima: 14 caracteres.
- Complejidad: habilitada.
- Historial: 24 contraseñas.
- Vigencia máxima: 90 días.
- Vigencia mínima: 1 día.
- Cifrado reversible: deshabilitado.
- Umbral de bloqueo: 5 intentos fallidos.
- Duración del bloqueo: 15 minutos.
- Restablecimiento del contador: 15 minutos.

La política se validó con la cuenta temporal `test.bloqueo`. Tras cinco intentos incorrectos, Active Directory mostró `LockedOut=True` y `BadLogonCount=5`. Al finalizar las pruebas, la cuenta quedó deshabilitada.

## Baseline de CL01

### Hardening

- Cuenta de invitado deshabilitada.
- Enumeración anónima de cuentas SAM bloqueada.
- Enumeración anónima de cuentas y recursos compartidos SAM bloqueada.
- NTLMv2 obligatorio; LM y NTLM rechazados.
- No almacenar hashes LAN Manager.
- Firma digital SMB requerida en cliente y servidor.
- UAC y modo de aprobación de administrador habilitados.

### Firewall

Los perfiles Dominio, Privado y Público quedan:

- Firewall habilitado.
- Conexiones entrantes bloqueadas por defecto.
- Conexiones salientes permitidas por defecto.
- Registro de paquetes descartados habilitado.
- Registro de conexiones correctas deshabilitado.
- Tamaño máximo del registro: 16384 KB.
- Ruta: `%systemroot%\system32\LogFiles\Firewall\pfirewall.log`.

### Auditoría

CL01 audita:

- Sistema: extensión e integridad del sistema (aciertos y errores) y cambio de estado de seguridad (aciertos).
- Inicio/cierre de sesión: inicio (aciertos y errores), cierre, bloqueo e inicio especial (aciertos).
- Seguimiento detallado: creación y finalización de procesos (aciertos).
- Cambio de directivas: auditoría, autenticación y autorización (aciertos y errores).
- Inclusión de la línea de comandos en los eventos de creación de procesos.

La ejecución controlada de `notepad.exe` generó el evento `4688`, incluyendo usuario, proceso creador y línea de comandos.

## Auditoría de DC01

DC01 audita:

- Administración de cuentas de equipo, grupos de seguridad, usuarios y otros eventos de cuentas.
- Acceso y cambios del servicio de directorio.
- Operaciones de vales Kerberos, servicio de autenticación Kerberos y validación de credenciales.
- Inicio de sesión, bloqueo y sesiones especiales.
- Cambios de directivas relevantes.

Para validar la configuración se modificó temporalmente la descripción de `test.bloqueo`, se restauró inmediatamente y se confirmó el evento `4738` en el registro de Seguridad.

## Incidencia y remediación

Durante la implementación, varias subcategorías propias del controlador de dominio se configuraron accidentalmente en `GPO-CL01-Security-Baseline`.

La incidencia se diagnosticó mediante:

1. `gpresult /scope computer /r` para confirmar las GPO aplicadas.
2. `auditpol /get /category:*` para revisar la política efectiva.
3. Un informe `gpresult /h` para identificar la GPO prevalente de cada ajuste.

Se creó y vinculó `GPO-DC01-Audit-Policy` a la OU de controladores de dominio. Después se retiraron de CL01 las categorías de inicio de sesión de cuentas, administración de cuentas y acceso DS. Finalmente se restauraron y verificaron la auditoría de sistema, inicio/cierre de sesión, procesos y cambios de directiva propia de la estación.

La remediación respetó la separación de responsabilidades y evitó ampliar permisos o aplicar configuraciones a ciegas.

## Verificación

Comandos principales:

```powershell
gpupdate /force
gpresult /scope computer /r
auditpol /get /category:*

Get-NetFirewallProfile -PolicyStore ActiveStore |
    Select-Object Name, Enabled, DefaultInboundAction,
                  DefaultOutboundAction, LogBlocked,
                  LogAllowed, LogMaxSizeKilobytes
```

Informes exportados en DC01:

```text
C:\IZANLAB-Evidencias-GPO\GPO-CL01-Security-Baseline.html
C:\IZANLAB-Evidencias-GPO\GPO-DC01-Audit-Policy.html
```

## Resultado

El laboratorio dispone de políticas diferenciadas y verificadas para dominio, estación de trabajo y controlador de dominio. Las evidencias demuestran la aplicación efectiva de las GPO, el hardening del endpoint, el registro del firewall y la generación de eventos de seguridad reales.
