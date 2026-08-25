# Estructura de OU e incorporación de CL01 al dominio

## Objetivo

Organizar el dominio `izanlab.local` con una estructura lógica de unidades organizativas (OU), comprobar la resolución DNS desde el cliente e incorporar `CL01` al dominio.

## Entorno

| Equipo | Sistema | Dirección IPv4 | DNS | Función |
|---|---|---:|---:|---|
| DC01 | Windows Server 2019 | 10.10.10.10/24 | 10.10.10.10 | Controlador de dominio y DNS |
| CL01 | Windows 10 Enterprise | 10.10.10.20/24 | 10.10.10.10 | Equipo cliente del dominio |

Ambas máquinas están conectadas a la red interna aislada `LAB-AD` de VirtualBox. El laboratorio no utiliza una puerta de enlace porque esta fase no necesita acceso a Internet.

## Estructura implementada

```text
OU=IZANLAB
├── OU=Cuentas de servicio
├── OU=Equipos
│   ├── OU=Puestos de trabajo
│   └── OU=Servidores
├── OU=Grupos
└── OU=Usuarios
    ├── OU=Direccion
    ├── OU=Finanzas
    ├── OU=Recursos Humanos
    └── OU=Sistemas
```

Las OU se crearon con protección contra eliminación accidental. El script reproducible se encuentra en [`../scripts/New-LabOUStructure.ps1`](../scripts/New-LabOUStructure.ps1).

## Comprobaciones realizadas

En `CL01` se vació la caché DNS y se verificó la resolución del dominio y del controlador:

```powershell
ipconfig /flushdns
nslookup izanlab.local
nslookup DC01.izanlab.local
ping DC01.izanlab.local
```

Ambos nombres resolvieron a `10.10.10.10` y la conectividad ICMP fue correcta. El texto inicial `DNS request timed out` de `nslookup` no impidió la resolución directa; se revisará posteriormente al configurar la zona de búsqueda inversa.

El cliente se incorporó al dominio y se reinició:

```powershell
Add-Computer -DomainName "izanlab.local" -Credential "IZANLAB\Administrador" -Restart
```

Después se comprobó la identidad del dominio y la relación de confianza:

```powershell
whoami
$env:USERDNSDOMAIN
Test-ComputerSecureChannel
```

El canal seguro devolvió `True`. Finalmente, el objeto del equipo se trasladó a su OU correspondiente:

```powershell
Get-ADComputer -Identity "CL01" |
    Move-ADObject -TargetPath "OU=Puestos de trabajo,OU=Equipos,OU=IZANLAB,DC=izanlab,DC=local"
```

## Resultado

- AD DS y DNS están operativos.
- La jerarquía de OU está creada y protegida.
- `CL01` pertenece al dominio `izanlab.local`.
- La relación de confianza del cliente es válida.
- El objeto `CL01` está situado en `OU=Puestos de trabajo`.

## Siguiente paso

Crear usuarios de prueba y grupos de seguridad, aplicar el modelo AGDLP y asignar permisos por función empresarial.
