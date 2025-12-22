# -*- coding: utf-8 -*-
<#
.SYNOPSIS
    Herramienta Profesional de Mantenimiento de Windows - Version Tecnico v3.0
.DESCRIPTION
    Version intermedia con funciones de diagnostico, limpieza avanzada y generacion de informes.
    Diseñada para usuarios con conocimientos tecnicos intermedios.
.AUTHOR
    TheInkReaper
.VERSION
    3.0
#>

#region 0. VERIFICACION Y AJUSTE DE POLITICA DE EJECUCION
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
#endregion

#region 1. CONFIGURACION INICIAL Y PERMISOS
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Elevando permisos..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$originalExecutionPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($originalExecutionPolicy -ne 'RemoteSigned' -and $originalExecutionPolicy -ne 'Unrestricted') {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -Confirm:$false
}
#endregion

#region 2. LOGGING Y BIENVENIDA
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

function Show-WelcomeScreen {
    Clear-Host
    Write-Host "====================================================================" -ForegroundColor DarkYellow
    Write-Host "       BIENVENIDO A LA HERRAMIENTA DE MANTENIMIENTO TECNICO" -ForegroundColor Yellow
    Write-Host "====================================================================" -ForegroundColor DarkYellow
    Write-Host "INFORMACIÓN IMPORTANTE Y ADVERTENCIAS:" -ForegroundColor Red
    Write-Host "--------------------------------------------------------------------" -ForegroundColor DarkRed
    
    Write-Host "1.  PERMISOS DE ADMINISTRADOR: Asegúrese de ejecutar este script como administrador." -ForegroundColor White
    Write-Host "2.  PUNTO DE RESTAURACIÓN: Se recomienda crearlo antes de realizar cambios significativos." -ForegroundColor White
    Write-Host "3.  REINICIOS: Algunas tareas (como CHKDSK) requieren reiniciar el equipo para completarse." -ForegroundColor White
    Write-Host "4.  RIESGOS DE LAS FUNCIONES: Proceda con precaución." -ForegroundColor White
    Write-Host "    - Amarillo:" -ForegroundColor Yellow -NoNewLine
    Write-Host " La tarea requiere un reinicio o interacción manual." -ForegroundColor White
    Write-Host "    - Rojo:    " -ForegroundColor Red -NoNewLine
    Write-Host " La tarea es de ALTO RIESGO y puede causar inestabilidad." -ForegroundColor White

    Write-Host "--------------------------------------------------------------------" -ForegroundColor DarkRed
    Write-Host "`nPresione cualquier tecla para continuar..." -ForegroundColor Yellow
    $null = Read-Host
}
#endregion

#region 3. DEFINICIÓN DE TAREAS

function Limpiar-CacheDNS {
    Write-ConsoleLog "Limpiando Caché DNS..."
    try {
        ipconfig /flushdns | Out-Null
        Write-ConsoleLog "OK." -ColorName Green
    } catch {
        Write-ConsoleLog "Error." -ColorName Red
    }
}

function Limpiar-ArchivosTemporales {
    Write-ConsoleLog "Limpiando Archivos Temporales..."
    try {
        if (Test-Path $env:TEMP) {
            Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        $windowsTemp = Join-Path $env:SystemRoot "Temp"
        if (Test-Path $windowsTemp) {
            Remove-Item "$windowsTemp\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        Write-ConsoleLog "OK." -ColorName Green
    } catch {
        Write-ConsoleLog "Error." -ColorName Red
    }
}

function Vaciar-Papelera {
    Write-ConsoleLog "Vaciando Papelera..."
    try {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-ConsoleLog "OK." -ColorName Green
    } catch {
        Write-ConsoleLog "Error." -ColorName Red
    }
}

function Limpiar-CacheWindowsUpdate {
    Write-ConsoleLog "Limpiando Caché de WU..."
    try {
        Write-ConsoleLog "  - Deteniendo servicio de Windows Update..."
        Stop-Service -Name wuauserv -Force -ErrorAction Stop
        Start-Sleep -Seconds 2
        
        $wuPath = Join-Path $env:SystemRoot "SoftwareDistribution\Download"
        if (Test-Path $wuPath) {
            Write-ConsoleLog "  - Eliminando archivos de descarga..."
            Remove-Item "$wuPath\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        Write-ConsoleLog "  - Iniciando servicio de Windows Update..."
        Start-Service -Name wuauserv -ErrorAction Stop
        
        Write-ConsoleLog "OK." -ColorName Green
    } catch {
        Write-ConsoleLog "Error." -ColorName Red
    }
}

function Ejecutar-DISM {
    Write-ConsoleLog "Ejecutando DISM..."
    try {
        Write-Host "Paso 1/3: CheckHealth..." -ForegroundColor Cyan
        $dismOutput = (DISM /Online /Cleanup-Image /CheckHealth 2>&1 | Out-String).Trim()
        
        if ($dismOutput -like "*No component store corruption detected*") {
            Write-Host "  - No se detectó corrupción (CheckHealth)" -ForegroundColor Green
        } elseif ($dismOutput -like "*The component store is repairable*") {
            Write-Host "  - Corrupción reparable detectada (CheckHealth)" -ForegroundColor Yellow
        } else {
            Write-Host "  - Posible problema detectado (CheckHealth)" -ForegroundColor Yellow
        }
        
        Write-Host "Paso 2/3: ScanHealth..." -ForegroundColor Cyan
        $dismOutput = (DISM /Online /Cleanup-Image /ScanHealth 2>&1 | Out-String).Trim()
        
        if ($dismOutput -like "*No component store corruption detected*") {
            Write-Host "  - No se detectó corrupción (ScanHealth)" -ForegroundColor Green
        } elseif ($dismOutput -like "*The component store is repairable*") {
            Write-Host "  - Corrupción reparable detectada (ScanHealth)" -ForegroundColor Yellow
        } else {
            Write-Host "  - Posible problema detectado (ScanHealth)" -ForegroundColor Yellow
        }
        
        Write-Host "Paso 3/3: RestoreHealth..." -ForegroundColor Cyan
        $dismOutput = (DISM /Online /Cleanup-Image /RestoreHealth 2>&1 | Out-String).Trim()
        
        if ($dismOutput -like "*The restore operation completed successfully*") {
            Write-ConsoleLog "OK. DISM completado con éxito." -ColorName Green
        } else {
            Write-ConsoleLog "DISM completado con advertencias. Revisa el log." -ColorName Yellow
        }
    } catch {
        Write-ConsoleLog "Error." -ColorName Red
    }
}

function Ejecutar-SFC {
    Write-ConsoleLog "Ejecutando SFC..."
    try {
        Write-Host "Iniciando System File Checker... (esto puede tardar)" -ForegroundColor Cyan
        $sfcOutput = (sfc /scannow 2>&1 | Out-String).Trim()
        
        if ($sfcOutput -like "*Windows Resource Protection did not find any integrity violations*") {
            Write-ConsoleLog "OK. No se encontraron violaciones de integridad." -ColorName Green
        } elseif ($sfcOutput -like "*Windows Resource Protection found corrupt files and successfully repaired them*") {
            Write-ConsoleLog "OK. Archivos reparados." -ColorName Green
        } elseif ($sfcOutput -like "*Windows Resource Protection found corrupt files but was unable to fix*") {
            Write-ConsoleLog "Archivos corruptos encontrados pero no se pudieron reparar." -ColorName Red
        } else {
            Write-ConsoleLog "SFC completado. Verifica el log para más detalles." -ColorName Yellow
        }
    } catch {
        Write-ConsoleLog "Error." -ColorName Red
    }
}

function Ejecutar-CHKDSK {
    Write-ConsoleLog "Programar CHKDSK..."
    
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -ne $null }
    $drives | ForEach-Object { "- $($_.Name)" } | Write-Host
    
    $drive = Read-Host "Elige unidad"
    
    if ($drive -and ($drives.Name -contains $drive.ToUpper())) {
        Write-Host ""
        Write-Host "ADVERTENCIA: CHKDSK puede tardar horas y requiere reinicio." -ForegroundColor Red
        $confirm = Read-Host "¿Estás SEGURO de programar CHKDSK en $($drive.ToUpper()):? (S/N)"
        
        if ($confirm -match "[Ss]") {
            chkdsk "$($drive.ToUpper()):" /r
            Write-ConsoleLog "CHKDSK para $drive programado. REINICIAR." -ColorName Yellow
        } else {
            Write-ConsoleLog "Cancelado." -ColorName Yellow
        }
    } else {
        Write-ConsoleLog "Cancelado." -ColorName Yellow
    }
}

function Ver-SaludDiscos {
    Write-ConsoleLog "Estado S.M.A.R.T. de los discos..."
    Get-PhysicalDisk | Format-Table FriendlyName, MediaType, HealthStatus -AutoSize
    Write-ConsoleLog "Completado." -ColorName Green
}

function Verificar-ReinicioPendiente {
    Write-ConsoleLog "Verificando reinicios..."
    $needed = $false
    
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
    )
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            $needed = $true
            Write-ConsoleLog "Reinicio pendiente detectado." -ColorName Yellow
            break
        }
    }
    
    if (-not $needed) {
        Write-ConsoleLog "No se necesita reiniciar." -ColorName Green
    }
}

function Limpiar-VSS {
    Write-ConsoleLog "Limpieza de Puntos de Restauración..."
    
    $confirm = Read-Host "ADVERTENCIA: ¿Eliminar TODOS los puntos de restauración? (s/n)"
    
    if ($confirm -eq 's') {
        try {
            Write-ConsoleLog "Eliminando..."
            vssadmin delete shadows /all /quiet
            Write-ConsoleLog "OK." -ColorName Green
        } catch {
            Write-ConsoleLog "Error." -ColorName Red
        }
    } else {
        Write-ConsoleLog "Cancelado." -ColorName Yellow
    }
}

function Gestionar-PlanesEnergia {
    Write-ConsoleLog "Planes de Energía..."
    powercfg /list
    
    $guid = Read-Host "Pega el GUID a activar"
    
    if ($guid) {
        powercfg /setactive $guid
        Write-ConsoleLog "OK." -ColorName Green
    } else {
        Write-ConsoleLog "Cancelado." -ColorName Yellow
    }
}

function Crear-PuntoRestauracion {
    Write-ConsoleLog "Creando Punto de Restauración..."
    try {
        $description = "TotalCleanupTecnico_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Checkpoint-Computer -Description $description -RestorePointType "MODIFY_SETTINGS"
        Write-ConsoleLog "OK." -ColorName Green
    } catch {
        Write-ConsoleLog "Error." -ColorName Red
    }
}

function Generar-InformeSesion {
    Write-ConsoleLog "Generando informe de sesión..."
    try {
        $reportFileName = "TotalCleanupTecnico_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        $path = Join-Path $PSScriptRoot $reportFileName
        Add-Content -Path $path -Value $scriptLogContent.ToString()
        Write-ConsoleLog "Informe guardado en: $reportFileName" -ColorName Green
    } catch {
        Write-ConsoleLog "Error." -ColorName Red
    }
}

# NOTA: Esta funcion solo ejecuta tareas seguras y automaticas.
# Las tareas avanzadas (CHKDSK, VSS, Gestion de Energia) deben ejecutarse manualmente.
function Invoke-RunAllTasks {
    Write-ConsoleLog "=====================================================" "Blue" -NoTime
    Write-ConsoleLog "EJECUTAR TODAS LAS TAREAS SEGURAS" "Blue" -NoTime
    Write-ConsoleLog "=====================================================" "Blue" -NoTime
    Write-Host ""
    Write-Host "Este proceso ejecutará:" -ForegroundColor Cyan
    Write-Host "  - Limpieza de Cache DNS" -ForegroundColor White
    Write-Host "  - Limpieza de Archivos Temporales" -ForegroundColor White
    Write-Host "  - Vaciar Papelera de Reciclaje" -ForegroundColor White
    Write-Host "  - Limpieza de Cache de Windows Update" -ForegroundColor White
    Write-Host "  - Comandos DISM (CheckHealth, ScanHealth, RestoreHealth)" -ForegroundColor White
    Write-Host "  - SFC /scannow" -ForegroundColor White
    Write-Host "  - Crear Punto de Restauración (antes de comenzar)" -ForegroundColor White
    Write-Host "  - Generar Informe (al finalizar)" -ForegroundColor White
    Write-Host ""
    Write-Host "NOTA: Las siguientes tareas NO se incluyen y deben ejecutarse manualmente:" -ForegroundColor Yellow
    Write-Host "  - CHKDSK (requiere reinicio)" -ForegroundColor Yellow
    Write-Host "  - Limpieza de Puntos de Restauración (VSS)" -ForegroundColor Yellow
    Write-Host "  - Gestión de Planes de Energía" -ForegroundColor Yellow
    Write-Host ""
    
    $confirm = Read-Host "¿Deseas continuar? (S/N)"
    
    if ($confirm -notmatch "[Ss]") {
        Write-ConsoleLog "Operación cancelada por el usuario." -ColorName Yellow
        return
    }
    
    Write-ConsoleLog "=====================================================" "Blue"
    Write-ConsoleLog "Iniciando ejecución automática de tareas seguras..." "Blue"
    Write-ConsoleLog "=====================================================" "Blue"
    
    Crear-PuntoRestauracion
    Write-Host ""
    
    Limpiar-CacheDNS
    Write-Host ""
    
    Limpiar-ArchivosTemporales
    Write-Host ""
    
    Vaciar-Papelera
    Write-Host ""
    
    Limpiar-CacheWindowsUpdate
    Write-Host ""
    
    Ejecutar-DISM
    Write-Host ""
    
    Ejecutar-SFC
    Write-Host ""
    
    Generar-InformeSesion
    
    Write-ConsoleLog "=====================================================" "Blue"
    Write-ConsoleLog "Todas las tareas automáticas completadas." "Green"
    Write-ConsoleLog "=====================================================" "Blue"
    
    # NOTA ADICIONAL: Las siguientes tareas NO se incluyeron y deben ejecutarse manualmente si es necesario:
    Write-Host ""
    Write-Host "RECORDATORIO: Las tareas avanzadas (CHKDSK, VSS, Energía) no fueron ejecutadas." -ForegroundColor Yellow
    Write-Host "Ejecuta manualmente si es necesario desde el menú principal." -ForegroundColor Yellow
}

#endregion

#region 4. MENÚ Y BUCLE PRINCIPAL
function Show-MaintenanceMenu { 
    Clear-Host
    Write-Host "--- Herramienta de Mantenimiento TECNICO v3.0 ---" -ForegroundColor Yellow
    Write-Host "Selecciona una opción:" -ForegroundColor Cyan
    Write-Host "`n--- LIMPIEZA ---" -ForegroundColor Green
    "1. Limpiar Caché DNS", "2. Limpiar Archivos Temporales", "3. Vaciar Papelera", "4. Limpiar Caché de Windows Update" | ForEach-Object { Write-Host "  $_" }
    Write-Host "`n--- REPARACIÓN Y DIAGNÓSTICO ---" -ForegroundColor Green
    "5. Ejecutar Comandos DISM", "6. Ejecutar SFC /scannow", "7. Programar CHKDSK", "8. Ver Salud Discos (S.M.A.R.T.)", "9. Verificar Reinicio Pendiente" | ForEach-Object { Write-Host "  $_" }
    Write-Host "`n--- AVANZADO / UTILIDADES ---" -ForegroundColor Yellow
    "10. Gestionar Planes de Energía" | ForEach-Object { Write-Host "  $_" }
    Write-Host "  11. Limpiar Puntos de Restauración (VSS)" -ForegroundColor Red
    "12. Crear Punto de Restauración", "13. Generar Informe de Sesión" | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
    Write-Host "`n--- AUTOMATIZACIÓN ---" -ForegroundColor Magenta
    Write-Host "  14. EJECUTAR TODAS LAS TAREAS SEGURAS" -ForegroundColor Magenta
    Write-Host "`n0. Salir" -ForegroundColor Red
}

Show-WelcomeScreen

try {
    do {
        Show-MaintenanceMenu
        $choice = Read-Host "`nIngresa tu opción"
        $scriptLogContent.Clear()
        
        switch ($choice) {
            "1" { Limpiar-CacheDNS }
            "2" { Limpiar-ArchivosTemporales }
            "3" { Vaciar-Papelera }
            "4" { Limpiar-CacheWindowsUpdate }
            "5" { Ejecutar-DISM }
            "6" { Ejecutar-SFC }
            "7" { Ejecutar-CHKDSK }
            "8" { Ver-SaludDiscos }
            "9" { Verificar-ReinicioPendiente }
            "10" { Gestionar-PlanesEnergia }
            "11" { Limpiar-VSS }
            "12" { Crear-PuntoRestauracion }
            "13" { Generar-InformeSesion }
            "14" { Invoke-RunAllTasks }
            "0" { break }
            default { Write-ConsoleLog "Opción no válida." -ColorName Red }
        }
        
        if ($choice -ne "0") {
            Write-Host "`nPresiona cualquier tecla para volver al menú..."
            $null = Read-Host
        }
    } while ($choice -ne "0")
} finally {
    if ($originalExecutionPolicy -ne (Get-ExecutionPolicy -Scope CurrentUser)) {
        Set-ExecutionPolicy -ExecutionPolicy $originalExecutionPolicy -Scope CurrentUser -Force -Confirm:$false
    }
    Write-ConsoleLog "Herramienta finalizada." -ColorName Green
}
#endregion
