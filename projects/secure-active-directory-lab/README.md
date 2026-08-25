## Hito: dominio, OU y cliente operativo

Se ha desplegado el dominio de laboratorio `izanlab.local` sobre Windows Server 2019, con servicios AD DS y DNS. También se ha creado una estructura empresarial de unidades organizativas y se ha incorporado el cliente Windows 10 `CL01` al dominio.

Resultados verificados:

- Resolución DNS del dominio y del controlador `DC01`.
- Canal seguro entre `CL01` y el dominio.
- Estructura de OU protegida contra eliminación accidental.
- Objeto de equipo `CL01` ubicado en la OU de puestos de trabajo.
- Creación reproducible de las OU mediante PowerShell.

Documentación: [`docs/03-ou-structure-and-client-join.md`](docs/03-ou-structure-and-client-join.md)

Script: [`scripts/New-LabOUStructure.ps1`](scripts/New-LabOUStructure.ps1)
