Herramienta de Mantenimiento para Windows
Creado por TheInkReaper

Una colección de scripts de PowerShell diseñados para ayudar a los usuarios a limpiar, reparar y optimizar su sistema operativo Windows de manera interactiva.

¿Qué edición elegir?
Este proyecto ofrece tres ediciones con diferentes niveles de funcionalidad. Elige la que mejor se adapte a tus necesidades.

1. Mantenimiento Básico
Archivo: TotalCleanup-Basico.ps1

Ideal para: Una limpieza rápida y segura. Perfecto para usuarios que quieren mejorar el rendimiento sin tocar opciones complejas.

Funciones:

Limpieza de cachés (DNS, temporales, Windows Update, navegadores).

Vaciado de la Papelera de Reciclaje.

Herramientas de reparación esenciales (DISM, SFC, CHKDSK).

Opción para ejecutar todas las tareas de forma automática.

2. Mantenimiento Extendido
Archivo: TotalCleanup-Extendido.ps1

Ideal para: Usuarios que necesitan más control y funciones de seguridad. Incluye todo lo de la edición Básica y añade herramientas importantes.

Nuevas Funciones:

Creación de Puntos de Restauración: La función más importante. Permite revertir cambios si algo sale mal.

Generación de Informes: Crea un archivo .log con los resultados de las operaciones.

Desfragmentación Inteligente: Solo desfragmenta discos HDD, protegiendo los SSD.

Limpieza de Logs de Eventos: Opción para borrar los registros de eventos de Windows.

Guías Seguras: Ofrece guías para tareas delicadas como la gestión del inicio o la actualización de drivers.

3. Mantenimiento Completo
Archivo: TotalCleanup-Completo.ps1

Ideal para: Usuarios avanzados y técnicos que necesitan un control total sobre el sistema. Incluye todo lo anterior y añade herramientas de diagnóstico y optimización de alto nivel.

Nuevas Funciones:

Diagnóstico de Discos (S.M.A.R.T.): Comprueba el estado de salud de los discos duros y SSD.

Gestión de Planes de Energía: Permite cambiar fácilmente entre perfiles de rendimiento.

Limpieza de Puntos de Restauración (VSS): Herramienta para eliminar todos los puntos de restauración y liberar espacio. (Acción de riesgo).

¿Cómo se usan?
Descarga el archivo .ps1 de la edición que quieras usar.

Haz clic derecho sobre el archivo.

Selecciona "Ejecutar con PowerShell".

Si aparece una ventana de Control de Cuentas de Usuario (UAC), acepta para conceder los permisos de administrador.

Sigue las instrucciones del menú interactivo en la consola.

Descargo de Responsabilidad
Estas herramientas se proporcionan "tal cual". Úsalas bajo tu propio riesgo. Se recomienda encarecidamente crear un punto de restauración antes de realizar cambios importantes en el sistema.
