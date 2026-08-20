# Hallazgos y recomendaciones

Las severidades son orientativas y se basan en el impacto demostrado dentro del laboratorio, no en una puntuación CVSS formal.

## THM-01: información interna en el código fuente

**Severidad:** Baja  
**Descripción:** El contenido público incluía una referencia a infraestructura interna que facilitó la enumeración posterior.  
**Impacto:** Reduce el esfuerzo necesario para descubrir activos que no deberían anunciarse.  
**Recomendación:** Eliminar comentarios, nombres internos y referencias de desarrollo antes de desplegar; integrar revisiones automáticas en el proceso de publicación.

## THM-02: archivo de respaldo accesible

**Severidad:** Alta  
**Descripción:** Un archivo antiguo permanecía disponible desde el servidor web.  
**Impacto:** Exposición de lógica operativa y datos que ayudaron a obtener acceso a otros servicios.  
**Recomendación:** Guardar copias fuera del directorio publicado, bloquear extensiones de respaldo y revisar periódicamente los recursos accesibles.

## THM-03: credenciales almacenadas en un script

**Severidad:** Alta  
**Descripción:** Un script contenía credenciales en texto claro.  
**Impacto:** Cualquier persona que accediera al archivo podía autenticarse en el servicio asociado.  
**Recomendación:** Revocar las credenciales expuestas, rotarlas y utilizar un gestor de secretos o credenciales de corta duración.

## THM-04: lectura arbitraria de archivos locales

**Severidad:** Crítica  
**Descripción:** La aplicación utilizaba una entrada controlada por el usuario para seleccionar archivos sin una validación adecuada.  
**Impacto:** Lectura de configuración, usuarios y material sensible del sistema.  
**Recomendación:** Sustituir rutas proporcionadas por el usuario por identificadores internos, aplicar una lista permitida, canonicalizar la ruta y ejecutar el servicio con privilegios mínimos.

## THM-05: material de autenticación SSH expuesto

**Severidad:** Crítica  
**Descripción:** La vulnerabilidad anterior permitió acceder a material válido para autenticación remota.  
**Impacto:** Suplantación de la cuenta afectada y acceso interactivo al servidor.  
**Recomendación:** Revocar inmediatamente la clave, generar una nueva, protegerla con frase de paso y revisar registros y permisos. Los secretos nunca deben almacenarse en ubicaciones legibles por el servicio web.

## THM-06: configuración insegura de sudo

**Severidad:** Alta  
**Descripción:** Una cuenta podía ejecutar un script delegado sin controles suficientes sobre sus entradas y su comportamiento.  
**Impacto:** Ejecución de acciones en el contexto de otro usuario.  
**Recomendación:** Aplicar mínimo privilegio, permitir únicamente binarios y argumentos imprescindibles, usar rutas absolutas y evitar scripts modificables o interpretables por el usuario.

## THM-07: script privilegiado modificable

**Severidad:** Crítica  
**Descripción:** Un proceso privilegiado ejecutaba un script sobre el que un usuario de menor confianza tenía capacidad de escritura.  
**Impacto:** Ejecución arbitraria como administrador y compromiso total del sistema.  
**Recomendación:** Asignar el archivo y su directorio a `root`, retirar permisos de escritura a grupos no autorizados, verificar integridad y revisar tareas programadas y servicios que ejecuten scripts.

## Prioridad de remediación

1. Revocar claves y credenciales expuestas.
2. Corregir la lectura arbitraria de archivos.
3. Proteger los scripts ejecutados con privilegios.
4. Revisar la política de `sudo`.
5. Retirar archivos de respaldo del servidor web.
6. Implantar revisiones de secretos, permisos e integridad.

