# -*- coding: utf-8 -*-
<#
.SYNOPSIS
    Herramienta de Mantenimiento de Windows basada en PowerShell (Version de Consola PRO).
    Ofrece opciones avanzadas para limpiar, reparar y optimizar el sistema mediante seleccion interactiva.

.DESCRIPTION
    Este script permite al usuario seleccionar y ejecutar diversas tareas de mantenimiento del sistema
    directamente en la consola. Incluye limpieza, reparacion, optimizacion y gestion de componentes del sistema.
    Disenado para mejorar el rendimiento, la estabilidad y la gestion del sistema operativo Windows.

.AUTHOR
    TheInkReaper

.NOTES
    Requiere permisos de administrador para la mayoria de las operaciones.
    Se recomienda ejecutarlo haciendo clic derecho y "Ejecutar como administrador".
    Las operaciones de CHKDSK requieren un reinicio para completarse.
    Algunas operaciones son AVANZADAS y requieren conocimientos. Proceda con precaucion.
#>

# ==============================================================================
# Paso 1: Comprobar Permisos de Administrador y Re-ejecutar si es necesario
# ==============================================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Este script requiere permisos de administrador para ejecutarse." -ForegroundColor Red
    Write-Host "Intentando elevar permisos..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -File `"$PSCommandPath`""
    exit
}

Write-Host "Iniciando la Herramienta de Mantenimiento del Sistema (modo consola)..." -ForegroundColor Cyan
Write-Host "Asegurese de ejecutar esta ventana como administrador." -ForegroundColor Yellow
Write-Host "--------------------------------------------------------" -ForegroundColor DarkCyan

# ==============================================================================
# Paso 2: Funcion de Registro en Consola y Utilidades
# ==============================================================================

$scriptLogContent = New-Object System.Text.StringBuilder

function Write-ConsoleLog {
    Param(
        [string]$Message,
        [string]$ColorName = "Green",
        [switch]$NoTime 
    )
    $output = if ($NoTime) { $Message } else { "$((Get-Date -Format 'HH:mm:ss')) - $Message" }
    Write-Host $output -ForegroundColor $ColorName
    if (-not $NoTime) {
        [void]$scriptLogContent.AppendLine($output)
    }
}

function Create-SystemRestorePoint {
    Write-ConsoleLog "Iniciando: Creacion de Punto de Restauracion del Sistema..." "Blue"
    try {
        if (-not (Get-ComputerRestorePoint -ErrorAction SilentlyContinue)) {
            Write-ConsoleLog "  - El servicio de proteccion del sistema no esta activo. Intentando habilitarlo..." "Yellow"
            Enable-ComputerRestore -Drive "C:\" -ErrorAction Stop
            Start-Sleep -Seconds 2 
        }
        
        $description = "TotalCleanupPro_AntesDeMantenimiento_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Checkpoint-Computer -Description $description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-ConsoleLog "Completado: Punto de Restauracion '$description' creado con exito." "Green"
    } catch {
        Write-ConsoleLog "Error al crear Punto de Restauracion: $($_.Exception.Message)" "Red"
        Write-ConsoleLog "  - Asegurese de que la proteccion del sistema esta habilitada para la unidad C:." "Red"
    }
}

function Generate-PostExecutionReport {
    Param(
        [string]$LogContent 
    )
    Write-ConsoleLog "Iniciando: Generacion de Informe Post-Ejecucion..." "Blue"
    $reportFileName = "TotalCleanupPro_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    $reportPath = Join-Path $PSScriptRoot $reportFileName

    try {
        $reportHeader = @"
=====================================================
Informe de Ejecucion - TotalCleanupConsolePro
Fecha y Hora: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
=====================================================

"@
        Add-Content -Path $reportPath -Value $reportHeader
        Add-Content -Path $reportPath -Value $LogContent
        
        Write-ConsoleLog "Completado: Informe guardado en '$reportPath'" "Green"
        Write-ConsoleLog "  - Puede abrir el archivo para revisar los detalles de la ejecucion." "Yellow"
    } catch {
        Write-ConsoleLog "Error al generar el informe: $($_.Exception.Message)" "Red"
    }
}

# ==============================================================================
# Paso 3: Definicion de Funciones para Cada Tarea de Mantenimiento
# ==============================================================================

# --- Tarea 1: Limpiar Cache de DNS ---
function Invoke-CleanDnsCache {
    Write-ConsoleLog "Iniciando: Limpieza de Cache DNS..." "Blue"
    try {
        ipconfig /flushdns | Out-Null
        Write-ConsoleLog "Completado: Cache DNS limpiada." "Green"
    } catch {
        Write-ConsoleLog "Error al limpiar Cache DNS: $($_.Exception.Message)" "Red"
    }
}

# --- Tarea 2: Limpiar Archivos Temporales (Usuario y Sistema) y Prefetch ---
function Invoke-CleanTemporaryFiles {
    Write-ConsoleLog "Iniciando: Limpieza de Archivos Temporales (Usuario, Sistema y Prefetch)..." "Blue"
    try {
        Write-ConsoleLog "  - Limpiando temporales de usuario ($env:TEMP)..."
        Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
        Write-ConsoleLog "  - Limpiando temporales de sistema (C:\Windows\Temp)..."
        Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
        Write-ConsoleLog "  - Limpiando archivos Prefetch (C:\Windows\Prefetch)..."
        Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
        
        Write-ConsoleLog "  - Ejecutando cleanmgr (limpieza adicional del sistema)..."
        Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -NoNewWindow -Wait -ErrorAction SilentlyContinue | Out-Null
        
        Write-ConsoleLog "Completado: Archivos Temporales y Prefetch limpiados." "Green"
    } catch {
        Write-ConsoleLog "Error al limpiar Archivos Temporales: $($_.Exception.Message)" "Red"
    }
}

# --- Tarea 3: Vaciar Papelera de Reciclaje ---
function Invoke-EmptyRecycleBin {
    Write-ConsoleLog "Iniciando: Vaciar Papelera de Reciclaje..." "Blue"
    try {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-ConsoleLog "Completado: Papelera de Reciclaje vaciada." "Green"
    } catch {
        Write-ConsoleLog "Error al vaciar Papelera de Reciclaje: $($_.Exception.Message)" "Red"
    }
}

# --- Tarea 4: Limpiar Cache de Windows Update ---
function Invoke-CleanWindowsUpdateCache {
    Write-ConsoleLog "Iniciando: Limpieza de Cache de Windows Update..." "Blue"
    try {
        Write-ConsoleLog "  - Deteniendo servicio de Windows Update..."
        Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
        
        Write-ConsoleLog "  - Eliminando archivos de descarga de actualizaciones..."
        Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
        
        Write-ConsoleLog "  - Iniciando servicio de Windows Update..."
        Start-Service -Name wuauserv -ErrorAction SilentlyContinue
        
        Write-ConsoleLog "Completado: Cache de Windows Update limpiada." "Green"
    } catch {
        Write-ConsoleLog "Error al limpiar Cache de Windows Update: $($_.Exception.Message)" "Red"
    }
}

# --- Tarea 5: Limpiar Caches Comunes de Usuario (Navegadores, etc.) ---
function Invoke-CleanUserCaches {
    Write-ConsoleLog "Iniciando: Limpieza de Caches Comunes de Usuario..." "Blue"
    try {
        $userCaches = @(
            "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
            "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",
            "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*\cache2",
            "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
            "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache",
            "$env:LOCALAPPDATA\Discord\Cache",
            "$env:LOCALAPPDATA\Spotify\Storage"
        )

        foreach ($cachePath in $userCaches) {
            try {
                $resolvedPath = Resolve-Path $cachePath -ErrorAction SilentlyContinue
                if ($resolvedPath) {
                    Write-ConsoleLog "  - Limpiando: $resolvedPath"
                    Remove-Item -Path "$resolvedPath\*" -Recurse -Force -ErrorAction SilentlyContinue
                } else {
                    Write-ConsoleLog "  - Ruta no encontrada o vacia (se omite): $cachePath" "Yellow"
                }
            } catch {
                Write-ConsoleLog "Error al limpiar la cache '$cachePath': $($_.Exception.Message)" "Red"
            }
        }
        Write-ConsoleLog "Completado: Caches Comunes de Usuario limpiadas." "Green"
    } catch {
        Write-ConsoleLog "Error general al limpiar Caches de Usuario: $($_.Exception.Message)" "Red"
    }
}

# --- Tarea 6: Limpiar Registros de Eventos ---
function Invoke-CleanEventLogs {
    Write-ConsoleLog "Iniciando: Limpieza de Registros de Eventos de Windows..." "Blue"
    Write-ConsoleLog "  - ADVERTENCIA: La eliminacion de logs de eventos puede dificultar el" "Yellow"
    Write-ConsoleLog "    diagnostico de problemas futuros. Proceda con precaucion." "Yellow"
    
    $confirm = Read-Host "Desea continuar con la limpieza de logs de eventos? (S/N)"
    if ($confirm -notmatch "[Ss]") {
        Write-ConsoleLog "Cancelado: Limpieza de Registros de Eventos." "Yellow"
        return
    }

    try {
        $eventLogNames = Get-WinEvent -ListLog * -ErrorAction SilentlyContinue | Where-Object {$_.RecordCount} | Select-Object -ExpandProperty LogName
        
        foreach ($logName in $eventLogNames) {
            try {
                Write-ConsoleLog "  - Limpiando log: $logName" "DarkGray"
                Clear-EventLog -LogName $logName -ErrorAction SilentlyContinue
            } catch {
                # El error action ya silencia la mayoria de errores (logs protegidos, etc.)
            }
        }
        Write-ConsoleLog "Completado: Registros de Eventos de Windows limpiados." "Green"
    } catch {
        Write-ConsoleLog "Error general al limpiar Registros de Eventos: $($_.Exception.Message)" "Red"
    }
}

# --- Tarea 7: Limpiar Puntos de Restauracion Antiguos ---
# RESTAURADO: Se vuelve a la funcionalidad original que lanza la herramienta gráfica cleanmgr.exe
function Invoke-CleanOldRestorePoints {
    Write-ConsoleLog "Iniciando: Limpieza de Puntos de Restauracion Antiguos..." "Blue"
    Write-ConsoleLog "  - ADVERTENCIA: Esta accion eliminara todos los puntos de restauracion excepto el mas reciente." "Yellow"
    Write-ConsoleLog "  - Asegurese de tener un punto de restauracion actual o no eliminar si no esta seguro." "Yellow"
    
    $confirm = Read-Host "Desea continuar con la eliminacion de puntos de restauracion antiguos? (S/N)"
    if ($confirm -notmatch "[Ss]") {
        Write-ConsoleLog "Cancelado: Limpieza de Puntos de Restauracion Antiguos." "Yellow"
        return
    }

    try {
        $restorePoints = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
        
        if ($restorePoints.Count -gt 1) {
            Write-ConsoleLog "  - Iniciando la limpieza de disco para eliminar puntos de restauracion antiguos (requiere interaccion manual)." "Yellow"
            # Estos comandos abren la utilidad de limpieza de disco. El usuario debe completar el proceso.
            # sageset abre la configuración, sagerun la ejecuta.
            Start-Process cleanmgr.exe -ArgumentList "/d C: /sageset:65535" -NoNewWindow -Wait -ErrorAction SilentlyContinue | Out-Null
            Start-Process cleanmgr.exe -ArgumentList "/d C: /sagerun:65535" -NoNewWindow -Wait -ErrorAction SilentlyContinue | Out-Null
            Write-ConsoleLog "  - Por favor, en la ventana de limpieza de disco, vaya a 'Más opciones' y use 'Restaurar sistema e instantáneas'." "Cyan"
            Write-ConsoleLog "Completado: Proceso de limpieza de Puntos de Restauracion Antiguos iniciado. Revise la herramienta de limpieza de disco." "Green"
        } elseif ($restorePoints.Count -eq 1) {
            Write-ConsoleLog "  - Solo se encontro un punto de restauracion. No se eliminara." "Yellow"
        } else {
            Write-ConsoleLog "  - No se encontraron puntos de restauracion para eliminar." "Yellow"
        }
    } catch {
        Write-ConsoleLog "Error al limpiar Puntos de Restauracion Antiguos: $($_.Exception.Message)" "Red"
    }
}

# --- Tarea 8: Ejecutar Comandos DISM (CheckHealth, ScanHealth, RestoreHealth) ---
function Invoke-DismCommands {
    Write-ConsoleLog "Iniciando: Ejecucion de Comandos DISM (esto puede tardar mucho)..." "Blue"
    Write-ConsoleLog "  - Se recomienda crear un punto de restauracion antes de ejecutar estas herramientas de reparacion." "Yellow"
    
    try {
        Write-ConsoleLog "  - DISM /Online /Cleanup-Image /CheckHealth..."
        $dismOutput = (DISM /Online /Cleanup-Image /CheckHealth 2>&1 | Out-String).Trim()
        Write-ConsoleLog "$dismOutput" "DarkGray"
        [void]$scriptLogContent.AppendLine("DISM CheckHealth Output:`n$dismOutput")
        if ($dismOutput -like "*No component store corruption detected*") {
            Write-ConsoleLog "  - No se detecto corrupcion en el almacen de componentes (CheckHealth)." "Green"
        } elseif ($dismOutput -like "*The component store is repairable*") {
            Write-ConsoleLog "  - Se detecto corrupcion reparable en el almacen de componentes (CheckHealth)." "Yellow"
        } else {
            Write-ConsoleLog "  - Resultado de CheckHealth: Posible corrupcion o problema." "Red"
        }
        
        Write-ConsoleLog "  - DISM /Online /Cleanup-Image /ScanHealth (esto puede tardar mas)..."
        $dismOutput = (DISM /Online /Cleanup-Image /ScanHealth 2>&1 | Out-String).Trim()
        Write-ConsoleLog "$dismOutput" "DarkGray"
        [void]$scriptLogContent.AppendLine("DISM ScanHealth Output:`n$dismOutput")
        if ($dismOutput -like "*No component store corruption detected*") {
            Write-ConsoleLog "  - No se detecto corrupcion en el almacen de componentes (ScanHealth)." "Green"
        } elseif ($dismOutput -like "*The component store is repairable*") {
            Write-ConsoleLog "  - Se detecto corrupcion reparable en el almacen de componentes (ScanHealth)." "Yellow"
        } else {
            Write-ConsoleLog "  - Resultado de ScanHealth: Posible corrupcion o problema." "Red"
        }

        Write-ConsoleLog "  - DISM /Online /Cleanup-Image /RestoreHealth (esto tambien puede tardar mucho)..."
        $dismOutput = (DISM /Online /Cleanup-Image /RestoreHealth 2>&1 | Out-String).Trim()
        Write-ConsoleLog "$dismOutput" "DarkGray"
        [void]$scriptLogContent.AppendLine("DISM RestoreHealth Output:`n$dismOutput")
        if ($dismOutput -like "*The restore operation completed successfully*") {
            Write-ConsoleLog "  - DISM RestoreHealth completado con exito." "Green"
        } else {
            Write-ConsoleLog "  - DISM RestoreHealth completado con errores o sin exito. Revisa el log." "Red"
        }
        Write-ConsoleLog "Completado: Ejecucion de Comandos DISM." "Green"
    } catch {
        Write-ConsoleLog "Error al ejecutar comandos DISM: $($_.Exception.Message)" "Red"
    }
}

# --- Tarea 9: Ejecutar SFC /scannow ---
function Invoke-SfcScan {
    Write-ConsoleLog "Iniciando: Ejecucion de SFC /scannow (esto puede tardar)..." "Blue"
    Write-ConsoleLog "  - Se recomienda crear un punto de restauracion antes de ejecutar estas herramientas de reparacion." "Yellow"
    try {
        $sfcOutput = (sfc /scannow 2>&1 | Out-String).Trim()
        Write-ConsoleLog "$sfcOutput" "DarkGray"
        [void]$scriptLogContent.AppendLine("SFC /scannow Output:`n$sfcOutput")
        if ($sfcOutput -like "*Windows Resource Protection did not find any integrity violations*") {
            Write-ConsoleLog "Completado: SFC /scannow no encontro violaciones de integridad." "Green"
        } elseif ($sfcOutput -like "*Windows Resource Protection found corrupt files and successfully repaired them*") {
            Write-ConsoleLog "Completado: SFC /scannow encontro y reparo archivos corruptos." "Green"
        } else {
            Write-ConsoleLog "Completado: SFC /scannow encontro problemas que no pudo reparar o tuvo un error." "Yellow"
        }
    } catch {
        Write-ConsoleLog "Error al ejecutar SFC /scannow: $($_.Exception.Message)" "Red"
    }
}

# --- Tarea 10: Ejecutar CHKDSK /r ---
function Invoke-ChkdskScan {
    Write-ConsoleLog "Iniciando: Ejecucion de CHKDSK C: /r (requerira reinicio y puede tardar mucho)." "Blue"
    Write-ConsoleLog "  - ADVERTENCIA: Esta operacion puede tardar horas y requiere un reinicio." "Red"
    Write-ConsoleLog "  - Se recomienda crear un punto de restauracion antes de programar CHKDSK." "Yellow"
    try {
        chkdsk C: /r
        Write-ConsoleLog "Completado: CHKDSK C: /r ha sido solicitado." "Green"
        Write-ConsoleLog "¡RECUERDA REINICIAR TU PC PARA QUE SE COMPLETE CHKDSK!" "Red"
    } catch {
        Write-ConsoleLog "Error al ejecutar CHKDSK: $($_.Exception.Message)" "Red"
    }
}

# --- Tarea 11: Desfragmentacion de Disco (Solo HDD) ---
function Invoke-DefragmentDisk {
    Write-ConsoleLog "Iniciando: Desfragmentacion de Disco (solo para HDD)." "Blue"
    try {
        $disk = Get-PhysicalDisk (Get-Partition -DriveLetter C).DiskNumber
        if ($disk.MediaType -eq 'HDD') {
            Write-ConsoleLog "  - Detectado disco duro HDD. Iniciando desfragmentacion de C:..."
            Optimize-Volume -DriveLetter C -Defrag -Verbose
            Write-ConsoleLog "Completado: Desfragmentacion de C: finalizada." "Green"
        } elseif ($disk.MediaType -eq 'SSD') {
            Write-ConsoleLog "  - Detectado disco SSD. La desfragmentacion no es necesaria y puede reducir la vida util del SSD." "Yellow"
            Write-ConsoleLog "  - Optimizacion (TRIM) en SSD se realiza automaticamente por el sistema." "Yellow"
        } else {
            Write-ConsoleLog "  - Tipo de unidad no reconocida ('$($disk.MediaType)') o no soportada para desfragmentacion." "Yellow"
        }
    } catch {
        Write-ConsoleLog "Error al desfragmentar disco: $($_.Exception.Message)" "Red"
    }
}

# --- Tarea 12: Reseteo de Configuracion de Red ---
function Invoke-ResetNetworkConfig {
    Write-ConsoleLog "Iniciando: Reseteo de Configuracion de Red (Winsock y TCP/IP)." "Blue"
    Write-ConsoleLog "  - ADVERTENCIA: Esta operacion puede requerir un reinicio para que los cambios surtan efecto." "Yellow"
    Write-ConsoleLog "  - Se recomienda crear un punto de restauracion antes de resetear la configuracion de red." "Yellow"
    try {
        Write-ConsoleLog "  - Reseteando Winsock Catalog..."
        netsh winsock reset | Out-Null
        Write-ConsoleLog "  - Reseteando TCP/IP Stack..."
        netsh int ip reset | Out-Null
        Write-ConsoleLog "Completado: Configuracion de red reseteada." "Green"
        Write-ConsoleLog "  - Puede que necesites reiniciar tu PC para que los cambios se apliquen completamente." "Red"
    } catch {
        Write-ConsoleLog "Error al resetear configuracion de red: $($_.Exception.Message)" "Red"
    }
}

# --- Tarea 13: Gestion de Programas de Inicio ---
function Invoke-ManageStartupPrograms {
    Write-ConsoleLog "Iniciando: Gestion de Programas de Inicio..." "Blue"
    Write-ConsoleLog "  - ADVERTENCIA: Deshabilitar programas esenciales de inicio puede afectar el funcionamiento del sistema." "Red"
    Write-ConsoleLog "  - Proceda con precaucion y solo deshabilite programas que conozca." "Yellow"
    
    try {
        Write-ConsoleLog "" 
        Write-ConsoleLog "Programas de Inicio Actuales:" "Cyan"
        Get-CimInstance Win32_StartupCommand | Format-Table Command, Location, User -AutoSize -Wrap
        
        Write-ConsoleLog "" 
        Write-ConsoleLog "Para gestionar programas de inicio de forma mas grafica y segura, use el Administrador de Tareas:" "Yellow"
        Write-ConsoleLog "  - Presione Ctrl+Shift+Esc para abrir el Administrador de Tareas." "Cyan"
        Write-ConsoleLog "  - Vaya a la pestaña 'Inicio' para habilitar/deshabilitar programas." "Cyan"
        Write-ConsoleLog "Completado: Informacion de Programas de Inicio mostrada." "Green"
    } catch {
        Write-ConsoleLog "Error al mostrar programas de inicio: $($_.Exception.Message)" "Red"
    }
}

# --- Tarea 14: Eliminacion de Programas no Utilizados y Restos de Software ---
function Invoke-UninstallPrograms {
    Write-ConsoleLog "Iniciando: Eliminacion de Programas no Utilizados y Restos de Software..." "Blue"
    Write-ConsoleLog "  - ADVERTENCIA: Esta es una operacion delicada. Desinstalar programas incorrectos puede desestabilizar el sistema." "Red"
    Write-ConsoleLog "  - Proceda con extrema precaucion y solo si esta seguro de lo que esta desinstalando." "Yellow"
    
    try {
        Write-ConsoleLog "" 
        Write-ConsoleLog "Para una desinstalacion segura y guiada, se recomienda:" "Yellow"
        Write-ConsoleLog "  - Ir a 'Configuracion' -> 'Aplicaciones' -> 'Aplicaciones y caracteristicas'." "Cyan"
        Write-ConsoleLog "  - O use 'Panel de control' -> 'Programas y caracteristicas'." "Cyan"
        
        Write-ConsoleLog ""
        Write-ConsoleLog "Completado: Guia para desinstalacion manual mostrada." "Green"
    } catch {
        Write-ConsoleLog "Error general en la funcion de desinstalacion: $($_.Exception.Message)" "Red"
    }
}

# --- Tarea 15: Buscar y Actualizar Controladores (Guia) ---
function Invoke-UpdateDrivers {
    Write-ConsoleLog "Iniciando: Busqueda y Actualizacion de Controladores..." "Blue"
    Write-ConsoleLog "  - ADVERTENCIA: La actualizacion de controladores debe hacerse con precaucion. Instalar un controlador incorrecto puede causar inestabilidad." "Red"
    Write-ConsoleLog "  - Siempre descargue controladores directamente desde el sitio web del fabricante de su hardware." "Yellow"
    
    Write-ConsoleLog "" 
    Write-ConsoleLog "Para buscar y actualizar controladores se recomienda:" "Cyan"
    Write-ConsoleLog "  1. Usar Windows Update (Configuracion -> Windows Update -> Opciones avanzadas -> Actualizaciones opcionales)." "Cyan"
    Write-ConsoleLog "  2. Visitar el sitio web del fabricante de su PC o de los componentes (tarjeta grafica, etc.) para descargar los controladores mas recientes." "Cyan"
    Write-ConsoleLog "  3. Usar el Administrador de Dispositivos (haga clic derecho en Inicio -> Administrador de Dispositivos) para actualizar controladores especificos." "Cyan"
    Write-ConsoleLog "Completado: Guia para la Actualizacion de Controladores mostrada." "Green"
}

# --- Tarea 16: Optimizacion de Servicios de Windows (Guia) ---
function Invoke-OptimizeWindowsServices {
    Write-ConsoleLog "Iniciando: Optimizacion de Servicios de Windows..." "Blue"
    Write-ConsoleLog "  - ADVERTENCIA: Modificar los servicios de Windows sin conocimiento puede" "Red"
    Write-ConsoleLog "    causar inestabilidad severa del sistema o perdida de funcionalidad." "Red"
    Write-ConsoleLog "  - Proceda con EXTREMA PRECAUCION. Si no esta seguro, NO toque los servicios." "Red"
    
    Write-ConsoleLog "" 
    Write-ConsoleLog "Para optimizar servicios de Windows de forma segura, se recomienda:" "Cyan"
    Write-ConsoleLog "  - Abrir el Administrador de Servicios (presione Win + R, escriba 'services.msc' y Enter)." "Cyan"
    Write-ConsoleLog "  - Investigar cada servicio antes de modificarlo." "Cyan"
    Write-ConsoleLog "  - Deshabilitar solo aquellos servicios que sepa que no necesita (ej. fax, Hyper-V si no lo usa)." "Cyan"
    Write-ConsoleLog "  - Establecer el 'Tipo de inicio' en 'Manual' para servicios que solo necesite ocasionalmente." "Cyan"
    Write-ConsoleLog "  - Evitar modificar servicios esenciales de Microsoft a menos que sepa exactamente lo que esta haciendo." "Cyan"
    Write-ConsoleLog "  - Hay guias en linea que sugieren servicios 'seguros' para deshabilitar, pero use con precaucion." "Yellow"
    Write-ConsoleLog "Completado: Guia para la Optimizacion de Servicios de Windows mostrada." "Green"
}


# --- Tarea 17: Ejecutar Todas las Tareas en Orden ---
function Invoke-RunAllTasks {
    Write-ConsoleLog "=====================================================" "Blue" -NoTime
    Write-ConsoleLog "Iniciando: Ejecucion de TODAS las tareas de mantenimiento." "Blue" -NoTime
    Write-ConsoleLog "=====================================================" "Blue" -NoTime

    Create-SystemRestorePoint

    Invoke-CleanDnsCache
    Invoke-CleanTemporaryFiles
    Invoke-EmptyRecycleBin
    Invoke-CleanWindowsUpdateCache
    Invoke-CleanUserCaches
    Invoke-CleanEventLogs
    Invoke-DefragmentDisk
    Invoke-DismCommands
    Invoke-SfcScan
    Invoke-ResetNetworkConfig
    Invoke-ChkdskScan

    Write-ConsoleLog "=====================================================" "Blue" -NoTime
    Write-ConsoleLog "Todas las tareas automaticas completadas." "Green" -NoTime
    Write-ConsoleLog "=====================================================" "Blue" -NoTime
    Write-ConsoleLog "NOTA: CHKDSK se ha PROGRAMADO. Debes REINICIAR el PC para que se complete." "Red"
    Write-ConsoleLog "NOTA: Algunas operaciones avanzadas (desinstalacion, drivers, etc.) son guias manuales." "Yellow"

    Generate-PostExecutionReport -LogContent $scriptLogContent.ToString()
}

# ==============================================================================
# Paso 4: Menu Interactivo de Consola
# ==============================================================================

function Show-MaintenanceMenu {
    param(
        [switch]$InitialCall
    )
    if ($InitialCall) {
        Clear-Host
    }
    
    Write-Host ""
    Write-Host "--- Herramienta de Mantenimiento del Sistema PRO ---" -ForegroundColor Yellow
    Write-Host "Selecciona una opcion:" -ForegroundColor Cyan
    Write-Host "------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "  SECCION DE LIMPIEZA Y OPTIMIZACION:" -ForegroundColor Green
    Write-Host "    1. Limpiar Cache DNS"
    Write-Host "    2. Limpiar Archivos Temporales (Usuario, Sistema y Prefetch)"
    Write-Host "    3. Vaciar Papelera de Reciclaje"
    Write-Host "    4. Limpiar Cache de Windows Update"
    Write-Host "    5. Limpiar Caches Comunes de Usuario (Navegadores, etc.)"
    Write-Host "    6. Limpiar Registros de Eventos de Windows (Precaucion)" -ForegroundColor Yellow
    Write-Host "    7. Desfragmentar Disco (Solo HDD)"
    Write-Host "    8. Limpiar Puntos de Restauracion Antiguos (Requiere interaccion manual)" -ForegroundColor Yellow
    Write-Host "------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "  SECCION DE REPARACION Y RESETEO:" -ForegroundColor Green
    Write-Host "    9. Ejecutar Comandos DISM (CheckHealth, ScanHealth, RestoreHealth)"
    Write-Host "   10. Ejecutar SFC /scannow"
    Write-Host "   11. Ejecutar CHKDSK C:/r (Requiere reinicio)" -ForegroundColor Yellow
    Write-Host "   12. Resetear Configuracion de Red (Winsock/TCP-IP)" -ForegroundColor Yellow
    Write-Host "------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "  SECCION AVANZADA / GUIA (PROCEDA CON PRECAUCION):" -ForegroundColor Red
    Write-Host "   13. Gestionar Programas de Inicio (Guia)"
    Write-Host "   14. Eliminar Programas no Utilizados (Guia)" -ForegroundColor Red
    Write-Host "   15. Buscar y Actualizar Controladores (Guia)"
    Write-Host "   16. Optimizar Servicios de Windows (Guia)" -ForegroundColor Red
    Write-Host "------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "  UTILIDADES ADICIONALES:" -ForegroundColor Green
    Write-Host "   17. Crear Punto de Restauracion del Sistema"
    Write-Host "   18. Generar Informe de Ejecucion"
    Write-Host "------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "  19. EJECUTAR TODAS LAS TAREAS (Automaticas y Seguras)" -ForegroundColor Magenta
    Write-Host "   0. Salir" -ForegroundColor Red
    Write-Host "------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host ""
}

# ==============================================================================
# Paso 5: Pantalla de Bienvenida
# ==============================================================================
function Show-WelcomeScreen {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor DarkYellow
    Write-Host "       BIENVENIDO A LA HERRAMIENTA DE MANTENIMIENTO PRO" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor DarkYellow
    Write-Host ""
    Write-Host "INFORMACION IMPORTANTE Y ADVERTENCIAS:" -ForegroundColor Red
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkRed
    Write-Host "1.  Requiere PERMISOS DE ADMINISTRADOR: Asegurese de ejecutar este script" -ForegroundColor White
    Write-Host "    como administrador para que todas las funciones operen correctamente." -ForegroundColor White
    Write-Host "2.  CREAR PUNTO DE RESTAURACION: Siempre se recomienda crear un punto de" -ForegroundColor White
    Write-Host "    restauracion del sistema antes de realizar cambios significativos." -ForegroundColor White
    Write-Host "    Este script ofrece una opcion para hacerlo (opcion 17 y al ejecutar TODAS)." -ForegroundColor White
    Write-Host "3.  OPERACIONES DE REINICIO: Algunas tareas (como CHKDSK C:/r) requieren" -ForegroundColor White
    Write-Host "    un REINICIO del equipo para completarse. El script le avisara." -ForegroundColor White
    Write-Host "4.  SECCION AVANZADA / GUIA: Las opciones en esta seccion (13, 14, 15, 16)" -ForegroundColor White
    Write-Host "    son mas delicadas y/o requieren interaccion manual y conocimientos." -ForegroundColor White
    Write-Host "    ¡PROCEDA CON EXTREMA PRECAUCION SI NO ESTA SEGURO DE LO QUE HACE!" -ForegroundColor Red
    Write-Host "    Desinstalar programas incorrectos o modificar el inicio o servicios puede afectar" -ForegroundColor White
    Write-Host "    la estabilidad del sistema." -ForegroundColor White
    Write-Host "5.  INFORME DE EJECUCION: Al finalizar, puede generar un informe (opcion 18)" -ForegroundColor White
    Write-Host "    con los detalles de las operaciones realizadas. Si elige 'Ejecutar TODAS'," -ForegroundColor White
    Write-Host "    el informe se generara automaticamente al final de ese proceso." -ForegroundColor White
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkRed
    Write-Host ""
    Write-Host "Presione cualquier tecla para continuar al menu principal..." -ForegroundColor Yellow
    $null = Read-Host
    Clear-Host
}

# ==============================================================================
# Paso 6: Bucle principal del menu
# ==============================================================================

Show-WelcomeScreen

$initial = $true
do {
    Show-MaintenanceMenu -InitialCall:$initial
    $initial = $false

    $choice = Read-Host "Ingresa tu opcion (0-19)"
    Write-Host ""

    $scriptLogContent.Clear()
    
    switch ($choice) {
        "1" { Invoke-CleanDnsCache }
        "2" { Invoke-CleanTemporaryFiles }
        "3" { Invoke-EmptyRecycleBin }
        "4" { Invoke-CleanWindowsUpdateCache }
        "5" { Invoke-CleanUserCaches }
        "6" { Invoke-CleanEventLogs }
        "7" { Invoke-DefragmentDisk }
        "8" { Invoke-CleanOldRestorePoints }
        "9" { Invoke-DismCommands }
        "10" { Invoke-SfcScan }
        "11" { Invoke-ChkdskScan }
        "12" { Invoke-ResetNetworkConfig }
        "13" { Invoke-ManageStartupPrograms }
        "14" { Invoke-UninstallPrograms }
        "15" { Invoke-UpdateDrivers }
        "16" { Invoke-OptimizeWindowsServices }
        "17" { Create-SystemRestorePoint }
        "18" { Generate-PostExecutionReport -LogContent $scriptLogContent.ToString() }
        "19" { Invoke-RunAllTasks }
        "0" { Write-ConsoleLog "Saliendo de la herramienta de mantenimiento. ¡Hasta pronto!" "Yellow"; break }
        default { Write-ConsoleLog "Opcion no valida. Por favor, selecciona un numero del 0 al 19." "Red" }
    }

    if ($choice -ne "0") {
        Write-Host ""
        Write-Host "Presiona cualquier tecla para volver al menu principal..." -ForegroundColor Yellow
        $null = Read-Host
        Clear-Host
    }

} while ($choice -ne "0")