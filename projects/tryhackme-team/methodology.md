# Metodología técnica

## 1. Alcance y autorización

El objetivo pertenecía a un entorno aislado de TryHackMe y estaba destinado a prácticas de ciberseguridad. Antes de comenzar se limitó el análisis a la máquina asignada y a los servicios asociados al reto.

## 2. Reconocimiento

Se realizó una exploración inicial de puertos y versiones para construir un inventario básico de la superficie de ataque. El análisis reveló servicios web y de administración remota que requerían una enumeración posterior.

Ejemplo de comando, con el objetivo anonimizado:

```bash
nmap -sC -sV TARGET_IP
```

La salida concreta se omite porque identifica la instancia temporal del laboratorio.

## 3. Enumeración web

La inspección del sitio y de su código fuente proporcionó una referencia a un nombre de host interno. Después de resolverlo únicamente dentro del laboratorio, se enumeraron rutas, extensiones y hosts virtuales.

Ejemplos genéricos:

```bash
gobuster dir -u http://TARGET_HOST/ -w WORDLIST
wfuzz -H "Host: FUZZ.TARGET_HOST" -w WORDLIST --hc 404 http://TARGET_IP/
```

El objetivo de esta fase no fue lanzar herramientas de forma indiscriminada, sino contrastar estas hipótesis:

- Existencia de contenido no enlazado desde la página principal.
- Presencia de archivos antiguos o copias de respaldo.
- Uso de hosts virtuales para separar entornos.

## 4. Análisis de exposición de información

Se identificó un archivo de respaldo accesible que contenía información operativa. Esta exposición permitió localizar credenciales reutilizadas y una referencia a otro recurso interno.

En el repositorio público se omiten el nombre exacto del archivo, las credenciales y los datos recuperados.

## 5. Validación de lectura de archivos

En un componente web se observó que un parámetro influía en la selección de archivos. Se comprobó de manera controlada que la validación era insuficiente y permitía acceder a archivos locales fuera del directorio previsto.

La prueba se limitó a la información imprescindible para demostrar el impacto. No se incluyen cargas útiles ni rutas específicas que revelen la solución del reto.

## 6. Acceso inicial

La información obtenida en fases anteriores condujo a material de autenticación SSH expuesto. Tras prepararlo con permisos locales restrictivos, se validó el acceso a una cuenta sin realizar cambios innecesarios en el objetivo.

La clave, el usuario y el procedimiento exacto se han retirado de esta versión.

## 7. Enumeración local

Una vez dentro se revisaron:

- Identidad y grupos del usuario.
- Permisos `sudo`.
- Archivos y directorios accesibles.
- Scripts ejecutables.
- Propietarios y permisos de escritura.
- Historial de comandos, usado únicamente como evidencia del laboratorio.
- Procesos y tareas automatizadas relevantes.

Ejemplos de comprobaciones básicas:

```bash
id
sudo -l
find / -writable -type f 2>/dev/null
```

## 8. Escalada de privilegios

Se detectaron dos configuraciones encadenables:

1. Un permiso de ejecución delegado sobre un script con controles insuficientes.
2. Un script privilegiado que podía ser modificado por un usuario sin privilegios.

La explotación controlada permitió demostrar el impacto máximo: ejecución con privilegios administrativos. Se detuvo la prueba al alcanzar el objetivo del laboratorio.

## 9. Registro y cierre

Se conservaron notas y capturas para elaborar la memoria académica. Para esta versión pública se revisó el material con estos criterios:

- Eliminar secretos y flags.
- Anonimizar direcciones y usuarios del reto.
- Evitar una guía reproducible respuesta por respuesta.
- Mantener suficientes detalles para demostrar la metodología aplicada.
- Asociar cada debilidad con una mitigación concreta.

