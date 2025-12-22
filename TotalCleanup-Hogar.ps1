# -*- coding: utf-8 -*-
<#
.SYNOPSIS
    Herramienta de Mantenimiento de Windows - Version Hogar v3.0
    Ofrece opciones para limpiar y reparar el sistema mediante seleccion interactiva.

.DESCRIPTION
    Este script permite al usuario seleccionar y ejecutar diversas tareas de mantenimiento del sistema
    directamente en la consola. Incluye limpieza de DNS, archivos temporales, papelera de reciclaje,
    cache de Windows Update, caches de usuario, y ejecucion de herramientas de reparacion como DISM,
    SFC y CHKDSK.

    Disenado para usuarios sin conocimientos tecnicos avanzados.
    Todas las operaciones son seguras y automaticas.

.AUTHOR
    TheInkReaper

.NOTES
    Requiere permisos de administrador para la mayoria de las operaciones.
    Se recomienda ejecutarlo haciendo clic derecho y "Ejecutar como administrador".
    Las operaciones de CHKDSK requieren un reinicio para completarse.
    
.VERSION
    3.0
#>

# ==============================================================================
# Paso 0: Verificar y Ajustar Politica de Ejecucion
# ==============================================================================

$currentPolicy = Get-ExecutionPolicy -Scope Process
if ($currentPolicy -eq 'Restricted' -or $currentPolicy -eq 'Undefined') {
    try {
        Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
    } catch {
        Write-Host "ERROR: No se pudo ajustar la politica de ejecucion." -ForegroundColor Red
        Write-Host "Ejecuta PowerShell como administrador y vuelve a intentarlo." -ForegroundColor Red
        Write-Host "Presiona cualquier tecla para salir..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
}

# ==============================================================================
# Paso 1: Comprobar Permisos de Administrador y Re-ejecutar si es necesario
# ==============================================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Este script requiere permisos de administrador para ejecutarse." -ForegroundColor Red
    Write-Host "Intentando elevar permisos..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

Write-Host "Iniciando la Herramienta de Mantenimiento del Sistema - Version Hogar v3.0" -ForegroundColor Cyan
Write-Host "Asegurese de ejecutar esta ventana como administrador." -ForegroundColor Yellow
Write-Host "--------------------------------------------------------" -ForegroundColor DarkCyan

# ==============================================================================
# Paso 2: Funcion de Registro en Consola
# ==============================================================================

function Write-ConsoleLog {
    Param(
        [string]$Message,
        [string]$ColorName = "Green"
    )
    $currentTime = Get-Date -Format 'HH:mm:ss'
    Write-Host "$currentTime - $Message" -ForegroundColor $ColorName
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
        if (Test-Path $env:TEMP) {
            Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        Write-ConsoleLog "  - Limpiando temporales de sistema (C:\Windows\Temp)..."
        if (Test-Path "C:\Windows\Temp") {
            Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        Write-ConsoleLog "  - Limpiando archivos Prefetch (C:\Windows\Prefetch)..."
        if (Test-Path "C:\Windows\Prefetch") {
            Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
        
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
        Stop-Service -Name wuauserv -ErrorAction SilentlyContinue
        
        Write-ConsoleLog "  - Eliminando archivos de descarga de actualizaciones..."
        if (Test-Path "C:\Windows\SoftwareDistribution\Download") {
            Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
        
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
                $resolvedPaths = Get-Item -Path "$cachePath\*" -ErrorAction SilentlyContinue
                
                if ($resolvedPaths) {
                    Write-ConsoleLog "  - Limpiando: $cachePath"
                    Remove-Item $resolvedPaths -Recurse -Force -ErrorAction Stop
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

# --- Tarea 6: Ejecutar Comandos DISM (CheckHealth, ScanHealth, RestoreHealth) ---
function Invoke-DismCommands {
    Write-ConsoleLog "Iniciando: Ejecucion de Comandos DISM (esto puede tardar mucho)..." "Blue"
    try {
        Write-ConsoleLog "  - DISM /Online /Cleanup-Image /CheckHealth..."
        $dismOutput = (DISM /Online /Cleanup-Image /CheckHealth 2>&1 | Out-String).Trim()
        if ($dismOutput -like "*No component store corruption detected*") {
            Write-ConsoleLog "  - No se detecto corrupcion en el almacen de componentes (CheckHealth)." "Green"
        } elseif ($dismOutput -like "*The component store is repairable*") {
            Write-ConsoleLog "  - Se detecto corrupcion reparable en el almacen de componentes (CheckHealth)." "Yellow"
        } else {
            Write-ConsoleLog "  - Resultado de CheckHealth: Posible corrupcion o problema." "Red"
        }
        
        Write-ConsoleLog "  - DISM /Online /Cleanup-Image /ScanHealth (esto puede tardar mas)..."
        $dismOutput = (DISM /Online /Cleanup-Image /ScanHealth 2>&1 | Out-String).Trim()
        if ($dismOutput -like "*No component store corruption detected*") {
            Write-ConsoleLog "  - No se detecto corrupcion en el almacen de componentes (ScanHealth)." "Green"
        } elseif ($dismOutput -like "*The component store is repairable*") {
            Write-ConsoleLog "  - Se detecto corrupcion reparable en el almacen de componentes (ScanHealth)." "Yellow"
        } else {
            Write-ConsoleLog "  - Resultado de ScanHealth: Posible corrupcion o problema." "Red"
        }

        Write-ConsoleLog "  - DISM /Online /Cleanup-Image /RestoreHealth (esto tambien puede tardar mucho)..."
        $dismOutput = (DISM /Online /Cleanup-Image /RestoreHealth 2>&1 | Out-String).Trim()
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

# --- Tarea 7: Ejecutar SFC /scannow ---
function Invoke-SfcScan {
    Write-ConsoleLog "Iniciando: Ejecucion de SFC /scannow (esto puede tardar)..." "Blue"
    try {
        $sfcOutput = (sfc /scannow 2>&1 | Out-String).Trim()
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

# --- Tarea 8: Ejecutar CHKDSK /r ---
function Invoke-ChkdskScan {
    Write-ConsoleLog "Iniciando: Ejecucion de CHKDSK C: /r (requerira reinicio y puede tardar mucho)." "Blue"
    Write-ConsoleLog "  - ADVERTENCIA: Esta operacion puede tardar horas y requiere un reinicio." "Red"
    
    $confirm = Read-Host "Estas SEGURO de que quieres programar CHKDSK? (S/N)"
    if ($confirm -notmatch "[Ss]") {
        Write-ConsoleLog "Cancelado: CHKDSK no fue programado." "Yellow"
        return
    }
    
    try {
        chkdsk C: /r
        Write-ConsoleLog "Completado: CHKDSK C: /r ha sido solicitado." "Green"
        Write-ConsoleLog "¡RECUERDA REINICIAR TU PC PARA QUE SE COMPLETE CHKDSK!" "Red"
    } catch {
        Write-ConsoleLog "Error al ejecutar CHKDSK: $($_.Exception.Message)" "Red"
    }
}

# --- Tarea 9: Ejecutar Todas las Tareas en Orden ---
function Invoke-RunAllTasks {
    Write-ConsoleLog "=====================================================" "Blue"
    Write-ConsoleLog "Iniciando: Ejecucion de TODAS las tareas de mantenimiento." "Blue"
    Write-ConsoleLog "=====================================================" "Blue"

    Invoke-CleanDnsCache
    Invoke-CleanTemporaryFiles
    Invoke-EmptyRecycleBin
    Invoke-CleanWindowsUpdateCache
    Invoke-CleanUserCaches
    Invoke-DismCommands
    Invoke-SfcScan
    Invoke-ChkdskScan

    Write-ConsoleLog "=====================================================" "Blue"
    Write-ConsoleLog "Todas las tareas automaticas completadas." "Green"
    Write-ConsoleLog "=====================================================" "Blue"
    Write-ConsoleLog "NOTA: CHKDSK se ha PROGRAMADO. Debes REINICIAR el PC para que se complete." "Red"
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
    Write-Host "--- Herramienta de Mantenimiento HOGAR v3.0 ---" -ForegroundColor Yellow
    Write-Host "Selecciona una opcion:" -ForegroundColor Cyan
    Write-Host "  1. Limpiar Cache DNS"
    Write-Host "  2. Limpiar Archivos Temporales (Usuario, Sistema y Prefetch)"
    Write-Host "  3. Vaciar Papelera de Reciclaje"
    Write-Host "  4. Limpiar Cache de Windows Update"
    Write-Host "  5. Limpiar Caches Comunes de Usuario (Navegadores, etc.)"
    Write-Host "  6. Ejecutar Comandos DISM (CheckHealth, ScanHealth, RestoreHealth)"
    Write-Host "  7. Ejecutar SFC /scannow"
    Write-Host "  8. Ejecutar CHKDSK C:/r (Requiere reinicio)"
    Write-Host "------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "  9. EJECUTAR TODAS LAS TAREAS" -ForegroundColor Magenta
    Write-Host "  0. Salir" -ForegroundColor Red
    Write-Host "------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host ""
}

# Bucle principal del menu
$initial = $true
do {
    Show-MaintenanceMenu -InitialCall:$initial
    $initial = $false

    $choice = Read-Host "Ingresa tu opcion (0-9)"
    Write-Host "" 

    switch ($choice) {
        "1" { Invoke-CleanDnsCache }
        "2" { Invoke-CleanTemporaryFiles }
        "3" { Invoke-EmptyRecycleBin }
        "4" { Invoke-CleanWindowsUpdateCache }
        "5" { Invoke-CleanUserCaches }
        "6" { Invoke-DismCommands }
        "7" { Invoke-SfcScan }
        "8" { Invoke-ChkdskScan }
        "9" { Invoke-RunAllTasks }
        "0" { Write-ConsoleLog "Saliendo de la herramienta de mantenimiento. ¡Hasta pronto!" "Yellow"; break }
        default { Write-ConsoleLog "Opcion no valida. Por favor, selecciona un numero del 0 al 9." "Red" }
    }

    if ($choice -ne "0") {
        Write-Host ""
        Write-Host "Presiona cualquier tecla para volver al menu principal..." -ForegroundColor Yellow
        $null = Read-Host
        Clear-Host
    }

} while ($choice -ne "0")
