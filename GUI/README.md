# TotalCleanup GUI v3.0 - Herramienta de Mantenimiento para Windows
Creado por **TheInkReaper**

Una aplicación de escritorio construida con PowerShell y Windows Forms que proporciona una interfaz gráfica intuitiva para ejecutar tareas de limpieza, reparación, diagnóstico y optimización en sistemas Windows.

## ✨ Características Clave
- **Tres Niveles de Experiencia**: Hogar (básico), Técnico (intermedio) y Profesional (avanzado), cada uno con las herramientas apropiadas para su nivel de conocimiento.
- **Interfaz Visual Mejorada**: Iconos en cada botón para identificar rápidamente el tipo de tarea, tooltips con tiempo estimado de ejecución.
- **Splash Screen**: Pantalla de carga animada al iniciar la aplicación.
- **Código de Colores por Riesgo**: Los botones se colorean según el nivel de peligro de la operación (Gris=Seguro, Verde=Recomendado, Amarillo=Precaución, Rojo=Peligro).
- **Estadísticas de Sesión**: Contador de tareas ejecutadas y tiempo de sesión accesible desde el menú Ayuda.
- **Atajos de Teclado**: Acceso rápido a las funciones más usadas.
- **Guías Integradas**: Ventanas informativas para tareas avanzadas como gestión de programas de inicio, controladores y servicios.
- **Lógica Multi-idioma**: Las funciones críticas de reparación (`DISM`, `SFC`) funcionan correctamente en cualquier idioma de Windows.

---

## 📋 Requisitos
- **Sistema Operativo**: Windows 10 / Windows 11
- **PowerShell**: Versión 5.1 o superior (instalado por defecto).
- **Permisos**: **Obligatorio ejecutar como Administrador**. La herramienta se auto-elevará si es necesario.

---

## 🚀 Cómo Usar
1.  Descarga el archivo `TotalCleanupGUI.ps1`.
2.  (Opcional) Descarga `icon.ico` en la misma carpeta para un icono personalizado de alta resolución.
3.  Haz clic derecho sobre `TotalCleanupGUI.ps1`.
4.  Selecciona **"Ejecutar con PowerShell"**.
5.  Acepta la petición de permisos de administrador (UAC).
6.  Selecciona tu nivel de experiencia (Hogar, Técnico o Profesional).
7.  Interactúa con los botones de la aplicación.

---

## ⌨️ Atajos de Teclado

| Atajo | Función |
|-------|---------|
| `Ctrl + S` | Guardar Log |
| `Ctrl + L` | Limpiar Log |
| `Ctrl + N` | Cambiar Nivel |
| `F1` | Leyenda de Colores |
| `Alt + F4` | Salir |

---

## 🎯 Niveles de Experiencia

### 🟢 Hogar (Básico)
Ideal para usuarios sin experiencia técnica. Incluye 8 tareas seguras:
- Limpieza de DNS, temporales, papelera, caché de Windows Update y navegadores
- Reparación con DISM y SFC
- Programación de CHKDSK

### 🟡 Técnico (Intermedio)
Para usuarios con conocimientos intermedios. Todo lo de Hogar más:
- Diagnóstico S.M.A.R.T. de discos
- Verificación de reinicios pendientes
- Gestión de planes de energía
- Creación de puntos de restauración
- Generación de informes
- ⚠️ Limpieza de VSS (puntos de restauración)

### 🔴 Profesional (Avanzado)
Control total del sistema. Incluye 18 funciones:
- Todo lo anterior más limpieza de registros de eventos
- Desfragmentación de disco (detecta HDD/SSD)
- Limpieza de puntos de restauración (modo híbrido)
- Reset de configuración de red
- Guías paso a paso para: programas de inicio, desinstalación, controladores y servicios
- **Dos modos de ejecución automática**: SEGURO y COMPLETO

---

## 🛠️ Descripción de las Funciones

#### 🧹 Limpieza
| Función | Descripción | Tiempo Est. |
|---------|-------------|-------------|
| Limpiar DNS | Resuelve problemas de conexión | ~5 seg |
| Limpiar Temporales | Libera espacio eliminando archivos temporales | ~30 seg |
| Vaciar Papelera | Elimina archivos de la papelera | Variable |
| Limpiar Cache WU | Limpia archivos de Windows Update | ~20 seg |
| Limpiar Navegadores | Limpia caché de Chrome, Edge, Firefox, etc. | ~30 seg |

#### 🔧 Reparación y Diagnóstico
| Función | Descripción | Tiempo Est. |
|---------|-------------|-------------|
| Ejecutar DISM | Repara la imagen del sistema | 5-15 min |
| Ejecutar SFC | Escanea y repara archivos del sistema | 5-10 min |
| Programar CHKDSK | Verifica el disco en el próximo reinicio | 1-3 horas |
| Ver Salud Discos | Muestra estado S.M.A.R.T. | ~5 seg |
| Verificar Reinicio | Detecta reinicios pendientes | ~3 seg |

#### ⚙️ Utilidades
| Función | Descripción | Riesgo |
|---------|-------------|--------|
| Crear Punto Restauración | **Recomendado** antes de cambios | ✅ Seguro |
| Gestionar Energía | Cambia planes de energía | ✅ Seguro |
| Generar Informe | Crea informe en el Escritorio | ✅ Seguro |
| Resetear Red | Resetea Winsock/TCP-IP | ⚠️ Precaución |

#### 📖 Guías (Solo Profesional)
- **Guía: Inicio** - Cómo gestionar programas de inicio
- **Guía: Desinstalar** - Cómo eliminar programas de forma segura
- **Guía: Drivers** - Cómo actualizar controladores correctamente
- **Guía: Servicios** - Cómo optimizar servicios de Windows

#### ☢️ Funciones de Alto Riesgo (Color Rojo)
- **Limpiar VSS**: **¡PELIGRO!** Elimina **TODOS** los puntos de restauración de forma irreversible.
- **Guía: Desinstalar**: Marcada en rojo porque una desinstalación incorrecta puede afectar al sistema.
- **Guía: Servicios**: Marcada en rojo porque modificar servicios puede causar inestabilidad severa.

---

## 🎨 Leyenda de Colores

| Color | Significado |
|-------|-------------|
| ⬜ Gris | Tarea segura, sin riesgos |
| 🟩 Verde | Acción recomendada |
| 🟨 Amarillo | Precaución, posibles efectos secundarios |
| 🟥 Rojo | PELIGRO, alto riesgo para el sistema |

---

## ⚠️ Descargo de Responsabilidad
Este software se proporciona "tal cual". El uso de esta herramienta, especialmente las funciones de alto riesgo, es bajo tu propia responsabilidad. El autor no se hace responsable de ninguna pérdida de datos o daño al sistema. **Siempre crea un punto de restauración antes de realizar operaciones críticas.**

---

## 📁 Archivos del Proyecto

```
TotalCleanup/
├── TotalCleanupGUI.ps1    # Script principal (incluye icono incrustado)
├── icon.ico               # (Opcional) Icono de alta resolución
└── README.md              # Este archivo
```
