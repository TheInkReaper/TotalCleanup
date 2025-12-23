# 🧹 TotalCleanup - Herramienta de Mantenimiento para Windows

**Versión 3.0** | Creado por TheInkReaper

Una colección de scripts de PowerShell diseñados para ayudar a los usuarios a limpiar, reparar y optimizar su sistema operativo Windows de manera interactiva y segura.

---

## ✨ ¿Qué hay nuevo en la versión 3.0?

- ✅ **Nueva nomenclatura clara**: Hogar, Técnico, Profesional
- ✅ **Corrección automática de políticas de ejecución**: Ya no necesitas configurar PowerShell manualmente
- ✅ **Modo "Ejecutar Todo"** en las tres versiones con diferentes niveles de automatización
- ✅ **Mejor manejo de errores** y validación de rutas
- ✅ **Interfaz mejorada** con advertencias más claras
- ✅ **Solución híbrida para limpieza de puntos de restauración** (Profesional)
- ✅ **🆕 Versión con Interfaz Gráfica (GUI)** - ¡Nueva!

---

## 🖥️ NUEVO: Versión con Interfaz Gráfica (GUI)

**Archivo:** `GUI/TotalCleanupGUI.ps1`

¿Prefieres botones en lugar de menús de texto? La nueva versión GUI incluye:

- 🎨 **Interfaz visual** con botones organizados por categorías
- 🎯 **Tres niveles** (Hogar, Técnico, Profesional) en una sola aplicación
- 🚦 **Código de colores** para identificar el riesgo de cada tarea
- ⏱️ **Tiempo estimado** en cada botón
- 📊 **Estadísticas de sesión** y contador de tareas
- ⌨️ **Atajos de teclado** (Ctrl+S, Ctrl+L, Ctrl+N, F1)
- 📖 **Guías integradas** en ventanas emergentes
- 🖼️ **Splash screen** al iniciar

### ¿Cómo usar la GUI?

1. Descarga `GUI/TotalCleanupGUI.ps1`
2. (Opcional) Descarga `GUI/icon.ico` en la misma carpeta
3. Clic derecho → "Ejecutar con PowerShell"
4. Selecciona tu nivel de experiencia
5. ¡Haz clic en los botones!

📁 **[Ver carpeta GUI](./GUI/)** para más información.

---

## 📦 ¿Qué edición elegir?

Este proyecto ofrece **tres ediciones** con diferentes niveles de funcionalidad. Elige la que mejor se adapte a tus necesidades y conocimientos técnicos.

| Versión | Interfaz | Ideal para |
|---------|----------|------------|
| **TotalCleanup-Hogar** | Consola | Usuarios básicos |
| **TotalCleanup-Técnico** | Consola | Usuarios intermedios |
| **TotalCleanup-Profesional** | Consola | Profesionales IT |
| **TotalCleanupGUI** | Gráfica | Todos los niveles en una app |

---

### 🏠 **1. TotalCleanup-Hogar** (v3.0)
**Archivo:** `TotalCleanup-Hogar.ps1`

**Ideal para:** Usuarios sin conocimientos técnicos que necesitan una limpieza rápida y segura del sistema.

**Filosofía:** "Hazlo simple, hazlo seguro, sin decisiones complejas."

#### **Funciones incluidas:**
- ✅ Limpieza de caché DNS
- ✅ Limpieza de archivos temporales (usuario, sistema, prefetch)
- ✅ Vaciado de la Papelera de Reciclaje
- ✅ Limpieza de caché de Windows Update
- ✅ Limpieza de cachés de navegadores (Chrome, Firefox, Edge, Discord, Spotify)
- ✅ Herramientas de reparación: DISM (CheckHealth, ScanHealth, RestoreHealth)
- ✅ Herramientas de reparación: SFC /scannow
- ✅ Programación de CHKDSK (con confirmación)
- ✅ **Opción "Ejecutar Todo"**: Automatiza todas las tareas de forma segura

**¿Cuándo usarla?**
- Tu PC va lento y quieres limpiarlo
- Necesitas liberar espacio en disco
- Quieres reparar archivos del sistema sin complicaciones
- No tienes conocimientos técnicos avanzados

---

### 🔧 **2. TotalCleanup-Técnico** (v3.0)
**Archivo:** `TotalCleanup-Tecnico.ps1`

**Ideal para:** Usuarios con conocimientos intermedios que necesitan herramientas de diagnóstico y control adicional.

**Filosofía:** "Dame herramientas de diagnóstico y control sobre el sistema."

#### **Todo lo de Hogar, más:**
- ✅ **Ver salud de discos (S.M.A.R.T.)**: Diagnóstico del estado de HDD/SSD
- ✅ **Verificar reinicio pendiente**: Detecta si Windows necesita reiniciarse
- ✅ **Limpieza de puntos de restauración (VSS)**: Elimina todos los puntos antiguos
- ✅ **Gestión de planes de energía**: Cambia entre perfiles de rendimiento
- ✅ **Crear punto de restauración manual**: Protección antes de cambios importantes
- ✅ **Generar informe de sesión**: Archivo .log con todas las operaciones realizadas
- ✅ **Opción "Ejecutar Todo (Seguro)"**: Solo tareas automáticas sin riesgos

**¿Cuándo usarla?**
- Necesitas diagnóstico del estado del sistema
- Quieres crear puntos de restauración antes de cambios
- Trabajas en soporte técnico básico/intermedio
- Necesitas informes de las operaciones realizadas

---

### 💼 **3. TotalCleanup-Profesional** (v3.0)
**Archivo:** `TotalCleanup-Profesional.ps1`

**Ideal para:** Profesionales IT, técnicos avanzados y usuarios expertos que necesitan control total del sistema.

**Filosofía:** "Control total, optimización avanzada y guías para tareas complejas."

#### **Todo lo de Técnico, más:**
- ✅ **Limpieza de registros de eventos**: Borra logs de Windows (con confirmación)
- ✅ **Desfragmentación inteligente**: Solo en HDD, protege los SSD automáticamente
- ✅ **Limpieza híbrida de puntos de restauración**:
  - Opción 1: Eliminar todos automáticamente (vssadmin)
  - Opción 2: Herramienta gráfica de Windows (cleanmgr)
- ✅ **Reseteo de configuración de red**: Winsock y TCP/IP Stack
- ✅ **Guías profesionales** para tareas delicadas:
  - Gestión de programas de inicio
  - Desinstalación segura de software
  - Actualización de controladores
  - Optimización de servicios de Windows
- ✅ **DOS modos "Ejecutar Todo"**:
  - **COMPLETO**: Incluye todas las tareas avanzadas (con confirmaciones)
  - **SEGURO**: Solo tareas 100% seguras sin riesgos

**¿Cuándo usarla?**
- Eres técnico de sistemas o profesional IT
- Necesitas optimización profunda del sistema
- Trabajas con múltiples equipos y necesitas informes detallados
- Requieres acceso a funciones avanzadas con seguridad

---

## 🚀 ¿Cómo se usan?

### **Método Recomendado:**

1. **Descarga** el archivo `.ps1` de la edición que necesites
2. **Haz clic derecho** sobre el archivo
3. Selecciona **"Ejecutar con PowerShell"**
4. Si aparece una ventana de **Control de Cuentas de Usuario (UAC)**, acepta para conceder permisos de administrador
5. El script ajustará automáticamente las políticas de ejecución si es necesario
6. **Sigue las instrucciones** del menú interactivo en la consola

### **Método Alternativo (si falla):**

1. Abre **PowerShell como Administrador**:
   - Presiona `Win + X`
   - Selecciona "Windows PowerShell (Administrador)"
2. Navega a la carpeta del script:
```powershell
   cd "C:\ruta\donde\descargaste\el\script"
```
3. Ejecuta el script:
```powershell
   .\TotalCleanup-Hogar.ps1
```

---

## ⚠️ Advertencias Importantes

### **Antes de Usar:**
- ✅ **Crea un punto de restauración** antes de realizar cambios importantes (las versiones Técnico y Profesional tienen esta opción)
- ✅ **Cierra todos los programas** antes de ejecutar las tareas de limpieza
- ✅ **Asegúrate de tener copia de seguridad** de archivos importantes

### **Durante el Uso:**
- ⚠️ Algunas operaciones como **DISM y SFC pueden tardar 30-60 minutos**
- ⚠️ **CHKDSK requiere reinicio** y puede tardar varias horas
- ⚠️ Las funciones marcadas en **rojo o amarillo** son de mayor riesgo

### **Tareas de Alto Riesgo:**
- 🔴 **Limpieza de registros de eventos**: Dificulta diagnósticos futuros
- 🔴 **Limpieza de puntos de restauración**: No podrás revertir cambios anteriores
- 🔴 **Optimización de servicios**: Puede causar inestabilidad si no sabes lo que haces
- 🟡 **Reseteo de red**: Puede requerir reconfiguración de conexiones

---

## 📊 Tabla Comparativa de Ediciones

| Característica | Hogar | Técnico | Profesional | GUI |
|----------------|:-----:|:-------:|:-----------:|:---:|
| **Limpieza básica** (DNS, temp, papelera, caches) | ✅ | ✅ | ✅ | ✅ |
| **Reparación** (DISM, SFC, CHKDSK) | ✅ | ✅ | ✅ | ✅ |
| **Diagnóstico de discos (S.M.A.R.T.)** | ❌ | ✅ | ✅ | ✅ |
| **Verificar reinicio pendiente** | ❌ | ✅ | ✅ | ✅ |
| **Crear punto de restauración** | ❌ | ✅ | ✅ | ✅ |
| **Generar informes** | ❌ | ✅ | ✅ | ✅ |
| **Limpieza de logs/eventos** | ❌ | ❌ | ✅ | ✅ |
| **Desfragmentación inteligente** | ❌ | ❌ | ✅ | ✅ |
| **Reseteo de red** | ❌ | ❌ | ✅ | ✅ |
| **Guías avanzadas** (drivers, servicios, inicio) | ❌ | ❌ | ✅ | ✅ |
| **Modo "Ejecutar Todo"** | ✅ Básico | ✅ Seguro | ✅ Completo + Seguro | ✅ Ambos |
| **Interfaz gráfica** | ❌ | ❌ | ❌ | ✅ |
| **Atajos de teclado** | ❌ | ❌ | ❌ | ✅ |
| **Selector de nivel** | ❌ | ❌ | ❌ | ✅ |

---

## 🛠️ Requisitos del Sistema

- **Sistema Operativo:** Windows 10 o Windows 11
- **PowerShell:** Versión 5.1 o superior (incluido en Windows)
- **Permisos:** Administrador (el script los solicita automáticamente)
- **Espacio:** Mínimo 100 MB libres para logs e informes

---

## 📁 Estructura del Proyecto

```
TotalCleanup/
├── README.md                      # Este archivo
├── TotalCleanup-Hogar.ps1         # Versión básica (consola)
├── TotalCleanup-Tecnico.ps1       # Versión intermedia (consola)
├── TotalCleanup-Profesional.ps1   # Versión avanzada (consola)
└── GUI/                           # Versión con interfaz gráfica
    ├── TotalCleanupGUI.ps1        # Aplicación GUI
    ├── icon.ico                   # Icono (opcional)
    └── README.md                  # Documentación de la GUI
```

---

## 📝 Notas de la Versión 3.0

### **Cambios Principales:**

**Nombres actualizados:**
- ~~Básico~~ → **Hogar**
- ~~Extendido~~ → **Técnico**
- ~~Completo~~ → **Profesional**

**Mejoras técnicas:**
- Verificación automática de políticas de ejecución
- Re-lanzamiento mejorado con `-ExecutionPolicy Bypass`
- Validación de rutas con `Test-Path` antes de limpiar
- Mejor feedback en DISM y SFC con outputs detallados
- Confirmaciones añadidas en operaciones críticas

**Nuevas funciones:**
- Botón "Ejecutar Todo" en las tres versiones
- Solución híbrida para limpieza de puntos de restauración
- Dos modos en Profesional: Completo y Seguro
- **🆕 Versión GUI completa con interfaz gráfica**

---

## 💬 Feedback

Si encuentras algún problema o tienes sugerencias para mejorar estas herramientas, puedes abrir un **Issue** en GitHub describiendo tu experiencia o comentarios.

---

## 📜 Licencia y Descargo de Responsabilidad

**Licencia:** Este proyecto es de código abierto.

**Descargo de Responsabilidad:**
Estas herramientas se proporcionan "tal cual", sin garantía de ningún tipo. El autor no se hace responsable de cualquier daño, pérdida de datos o problemas que puedan surgir del uso de estos scripts.

**Úsalas bajo tu propio riesgo.** Se recomienda encarecidamente:
- Crear un punto de restauración antes de usar
- Hacer copia de seguridad de archivos importantes
- Leer las advertencias de cada función antes de ejecutarla

---

## 👨‍💻 Autor

**TheInkReaper**

Si este proyecto te ha sido útil, considera darle una ⭐ en GitHub.

---

**Versión actual:** 3.0  
**Última actualización:** Diciembre 2025
