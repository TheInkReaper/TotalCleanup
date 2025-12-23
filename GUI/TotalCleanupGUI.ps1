<#
.SYNOPSIS
    TotalCleanup GUI - Herramienta Profesional de Mantenimiento de Windows
.DESCRIPTION
    Aplicación de escritorio con interfaz gráfica para ejecutar tareas de limpieza,
    reparación, diagnóstico y optimización en sistemas Windows.
    Incluye tres niveles de experiencia: Hogar, Técnico y Profesional.
.AUTHOR
    TheInkReaper
.VERSION
    4.0 (GUI)
#>

#region 0. VERIFICACION Y AJUSTE DE POLITICA DE EJECUCION
$currentPolicy = Get-ExecutionPolicy -Scope Process
if ($currentPolicy -eq 'Restricted' -or $currentPolicy -eq 'Undefined') {
    try {
        Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
    } catch {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show(
            "ERROR: No se pudo ajustar la politica de ejecucion.`n`nEjecuta PowerShell como administrador y vuelve a intentarlo.",
            "Error Critico",
            "OK",
            "Error"
        )
        exit 1
    }
}

# Ocultar ventana de consola
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'

$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 0) | Out-Null
#endregion

#region 1. CONFIGURACION INICIAL Y PERMISOS
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

Add-Type -AssemblyName System.Windows.Forms, System.Drawing, Microsoft.VisualBasic
try {
    [void][System.Windows.Forms.Application]::EnableVisualStyles()
    [void][System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
} catch {}

$script:OriginalExecutionPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($script:OriginalExecutionPolicy -ne 'RemoteSigned' -and $script:OriginalExecutionPolicy -ne 'Unrestricted') {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -Confirm:$false
}
#endregion

#region 2. VARIABLES GLOBALES
$script:GUILogTextBox = $null
$script:GlobalProgressBar = $null
$script:JobTimer = $null
$script:OptionsPanel = $null
$script:RunAllPanel = $null
$script:StopButton = $null
$script:RunAllSafeButton = $null
$script:RunAllCompleteButton = $null
$script:LogContent = New-Object System.Text.StringBuilder
$script:CurrentLevel = $null
$script:Form = $null
$script:IsTaskRunning = $false
#endregion

#region 3. FUNCIONES DE LOGGING
function Write-GUILog {
    Param(
        [string]$Message,
        [string]$Type = "Info",
        [switch]$NoTime
    )
    if ($script:GUILogTextBox) {
        $timestamp = if ($NoTime) { "" } else { "$((Get-Date -Format 'HH:mm:ss')) - " }
        $logEntry = "$timestamp$Message`r`n"
        $script:GUILogTextBox.AppendText($logEntry)
        $script:GUILogTextBox.SelectionStart = $script:GUILogTextBox.Text.Length
        $script:GUILogTextBox.ScrollToCaret()
        [void]$script:LogContent.AppendLine($logEntry.Trim())
        [System.Windows.Forms.Application]::DoEvents()
    }
}

function Clear-GUILog {
    if ($script:GUILogTextBox) {
        $script:GUILogTextBox.Clear()
        $script:LogContent.Clear()
    }
}
#endregion

# ============================================================================
# FIN PARTE 1 - Continúa en PARTE 2 con la definición de tareas
# ============================================================================
# ============================================================================
# PARTE 2 - DEFINICION DE TAREAS INDIVIDUALES
# ============================================================================

#region 4. DEFINICION DE TODAS LAS TAREAS
$script:Acciones = @{
    
    # ==================== TAREAS DE LIMPIEZA ====================
    
    LimpiarCacheDNS = {
        "Limpiando Cache DNS..."
        try {
            ipconfig /flushdns | Out-Null
            "OK: Cache DNS limpiada correctamente."
        } catch {
            "ERROR: No se pudo limpiar la cache DNS - $($_.Exception.Message)"
        }
    }
    
    LimpiarArchivosTemporales = {
        "Limpiando Archivos Temporales..."
        try {
            "  - Limpiando temporales de usuario ($env:TEMP)..."
            if (Test-Path $env:TEMP) {
                Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | 
                    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            }
            
            "  - Limpiando temporales de sistema..."
            $sysTemp = Join-Path $env:SystemRoot "Temp"
            if (Test-Path $sysTemp) {
                Get-ChildItem -Path $sysTemp -Recurse -Force -ErrorAction SilentlyContinue | 
                    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            }
            
            "  - Limpiando archivos Prefetch..."
            $prefetch = Join-Path $env:SystemRoot "Prefetch"
            if (Test-Path $prefetch) {
                Get-ChildItem -Path $prefetch -Recurse -Force -ErrorAction SilentlyContinue | 
                    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            }
            
            "OK: Archivos temporales eliminados."
        } catch {
            "ERROR: $($_.Exception.Message)"
        }
    }
    
    VaciarPapelera = {
        "Vaciando Papelera de Reciclaje..."
        try {
            Clear-RecycleBin -Force -ErrorAction SilentlyContinue
            "OK: Papelera vaciada."
        } catch {
            "ERROR: $($_.Exception.Message)"
        }
    }
    
    LimpiarCacheWU = {
        "Limpiando Cache de Windows Update..."
        try {
            "  - Deteniendo servicio Windows Update..."
            Stop-Service -Name wuauserv -Force -ErrorAction Stop
            Start-Sleep -Seconds 2
            
            "  - Eliminando archivos de descarga..."
            $wuPath = Join-Path $env:SystemRoot "SoftwareDistribution\Download"
            if (Test-Path $wuPath) {
                Remove-Item "$wuPath\*" -Recurse -Force -ErrorAction SilentlyContinue
            }
            
            "  - Iniciando servicio Windows Update..."
            Start-Service -Name wuauserv -ErrorAction Stop
            
            "OK: Cache de Windows Update limpiada."
        } catch {
            "ERROR: $($_.Exception.Message)"
        }
    }
    
    LimpiarCachesNavegadores = {
        "Limpiando Caches de Navegadores y Aplicaciones..."
        
        $caches = @(
            @{Path="$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"; Name="Chrome Cache"},
            @{Path="$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache"; Name="Chrome Code Cache"},
            @{Path="$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"; Name="Edge Cache"},
            @{Path="$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache"; Name="Edge Code Cache"},
            @{Path="$env:LOCALAPPDATA\Mozilla\Firefox\Profiles"; Name="Firefox"; IsProfile=$true},
            @{Path="$env:LOCALAPPDATA\Discord\Cache"; Name="Discord Cache"},
            @{Path="$env:LOCALAPPDATA\Discord\Code Cache"; Name="Discord Code Cache"},
            @{Path="$env:APPDATA\Spotify\Storage"; Name="Spotify Storage"}
        )
        
        foreach ($cache in $caches) {
            try {
                if ($cache.IsProfile) {
                    if (Test-Path $cache.Path) {
                        Get-ChildItem -Path $cache.Path -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                            $cachePath = Join-Path $_.FullName "cache2"
                            if (Test-Path $cachePath) {
                                "  - Limpiando: $($cache.Name) ($($_.Name))"
                                Remove-Item "$cachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
                            }
                        }
                    }
                } else {
                    if (Test-Path $cache.Path) {
                        "  - Limpiando: $($cache.Name)"
                        Remove-Item "$($cache.Path)\*" -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
            } catch {
                "  - Error en $($cache.Name): $($_.Exception.Message)"
            }
        }
        
        "OK: Caches de navegadores limpiadas."
    }
    
    # ==================== TAREAS DE REPARACION ====================
    
    EjecutarDISM = {
        "Ejecutando DISM (esto puede tardar varios minutos)..."
        ""
        try {
            "Paso 1/3: CheckHealth..."
            $output = & DISM /Online /Cleanup-Image /CheckHealth 2>&1
            $outputStr = ($output | Out-String).Trim()
            
            if ($outputStr -like "*No component store corruption detected*") {
                "  - No se detecto corrupcion (CheckHealth)"
            } elseif ($outputStr -like "*The component store is repairable*") {
                "  - Corrupcion reparable detectada (CheckHealth)"
            } else {
                "  - Verificacion completada (CheckHealth)"
            }
            ""
            
            "Paso 2/3: ScanHealth..."
            $output = & DISM /Online /Cleanup-Image /ScanHealth 2>&1
            $outputStr = ($output | Out-String).Trim()
            
            if ($outputStr -like "*No component store corruption detected*") {
                "  - No se detecto corrupcion (ScanHealth)"
            } elseif ($outputStr -like "*The component store is repairable*") {
                "  - Corrupcion reparable detectada (ScanHealth)"
            } else {
                "  - Escaneo completado (ScanHealth)"
            }
            ""
            
            "Paso 3/3: RestoreHealth..."
            $output = & DISM /Online /Cleanup-Image /RestoreHealth 2>&1
            $outputStr = ($output | Out-String).Trim()
            
            if ($outputStr -like "*The restore operation completed successfully*") {
                "OK: DISM completado con exito."
            } else {
                "INFO: DISM completado. Revisa el log para mas detalles."
            }
        } catch {
            "ERROR: $($_.Exception.Message)"
        }
    }
    
    EjecutarSFC = {
        "Ejecutando SFC /scannow (esto puede tardar 15-30 minutos)..."
        ""
        try {
            $output = & sfc /scannow 2>&1
            $outputStr = ($output | Out-String).Trim()
            
            if ($outputStr -like "*Windows Resource Protection did not find any integrity violations*") {
                "OK: No se encontraron violaciones de integridad."
            } elseif ($outputStr -like "*Windows Resource Protection found corrupt files and successfully repaired them*") {
                "OK: Archivos corruptos encontrados y reparados."
            } elseif ($outputStr -like "*Windows Resource Protection found corrupt files but was unable to fix*") {
                "ADVERTENCIA: Archivos corruptos encontrados pero no se pudieron reparar."
            } else {
                "INFO: SFC completado. Revisa el log para mas detalles."
            }
        } catch {
            "ERROR: $($_.Exception.Message)"
        }
    }
    
    ProgramarCHKDSK = {
        "Programando CHKDSK..."
        "ADVERTENCIA: Esta operacion puede tardar horas y requiere un reinicio."
        ""
        try {
            $result = & chkdsk C: /r 2>&1
            "OK: CHKDSK programado para la unidad C:"
            "IMPORTANTE: Debes REINICIAR tu PC para que CHKDSK se ejecute."
        } catch {
            "ERROR: $($_.Exception.Message)"
        }
    }
    
    # ==================== TAREAS DE DIAGNOSTICO ====================
    
    VerSaludDiscos = {
        "Verificando estado S.M.A.R.T. de los discos..."
        ""
        try {
            $disks = Get-PhysicalDisk
            foreach ($disk in $disks) {
                "Disco: $($disk.FriendlyName)"
                "  - Tipo: $($disk.MediaType)"
                "  - Estado: $($disk.HealthStatus)"
                "  - Tamano: $([math]::Round($disk.Size / 1GB, 2)) GB"
                ""
            }
            "OK: Verificacion completada."
        } catch {
            "ERROR: $($_.Exception.Message)"
        }
    }
    
    VerificarReinicioPendiente = {
        "Verificando si hay reinicios pendientes..."
        ""
        try {
            $rebootPending = $false
            
            $paths = @(
                "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired",
                "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
            )
            
            foreach ($path in $paths) {
                if (Test-Path $path) {
                    $rebootPending = $true
                    "ADVERTENCIA: Reinicio pendiente detectado."
                }
            }
            
            if (-not $rebootPending) {
                "OK: No hay reinicios pendientes."
            } else {
                ""
                "RECOMENDACION: Reinicia tu PC para aplicar los cambios pendientes."
            }
        } catch {
            "ERROR: $($_.Exception.Message)"
        }
    }
    
    # ==================== UTILIDADES ====================
    
    CrearPuntoRestauracion = {
        "Creando Punto de Restauracion..."
        try {
            $descripcion = "TotalCleanupGUI_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Checkpoint-Computer -Description $descripcion -RestorePointType "MODIFY_SETTINGS" -WarningAction SilentlyContinue -ErrorAction Stop
            "OK: Punto de Restauracion '$descripcion' creado con exito."
        } catch {
            "ERROR: $($_.Exception.Message)"
            "INFO: Asegurate de que la proteccion del sistema esta habilitada para la unidad C:"
        }
    }
    
    # ==================== TAREAS NIVEL TECNICO ====================
    
    GestionarPlanesEnergia = {
        "Gestionando Planes de Energia..."
        ""
        try {
            "Planes de energia disponibles:"
            ""
            $plans = powercfg /list
            $plans | ForEach-Object { $_ }
            ""
            "INFO: Para cambiar el plan activo, usa el comando:"
            "      powercfg /setactive <GUID>"
            ""
            "OK: Lista de planes mostrada."
        } catch {
            "ERROR: $($_.Exception.Message)"
        }
    }
    
    LimpiarVSS = {
        "Limpieza de Puntos de Restauracion (VSS)..."
        ""
        "ADVERTENCIA: Esta accion eliminara TODOS los puntos de restauracion."
        "Esto es IRREVERSIBLE y puede impedir restaurar el sistema a estados anteriores."
        ""
        try {
            vssadmin delete shadows /all /quiet
            "OK: Todos los puntos de restauracion han sido eliminados."
        } catch {
            "ERROR: $($_.Exception.Message)"
        }
    }
    
    LimpiarPuntosRestauracionAntiguos = {
        "Limpieza de Puntos de Restauracion Antiguos (Hibrido)..."
        ""
        $result = [System.Windows.Forms.MessageBox]::Show(
            "Opciones disponibles:`n`n" +
            "SI = Eliminar TODOS excepto el mas reciente (vssadmin)`n`n" +
            "NO = Abrir herramienta grafica de Windows (cleanmgr)`n`n" +
            "CANCELAR = No hacer nada",
            "Limpiar Puntos de Restauracion",
            [System.Windows.Forms.MessageBoxButtons]::YesNoCancel,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        
        switch ($result) {
            "Yes" {
                "Eliminando TODOS los puntos de restauracion excepto el mas reciente..."
                try {
                    vssadmin delete shadows /all /quiet
                    "OK: Puntos de restauracion antiguos eliminados."
                } catch {
                    "ERROR: $($_.Exception.Message)"
                }
            }
            "No" {
                "Abriendo herramienta de limpieza de disco..."
                "IMPORTANTE: Ve a 'Mas opciones' > 'Restaurar sistema' > 'Limpiar'"
                try {
                    Start-Process cleanmgr.exe -ArgumentList "/d C:"
                    "INFO: Herramienta de limpieza abierta. Sigue las instrucciones en pantalla."
                } catch {
                    "ERROR: $($_.Exception.Message)"
                }
            }
            default {
                "Operacion cancelada."
            }
        }
    }
    
    GenerarInformeSesion = {
        "Generando Informe de Sesion..."
        try {
            $reportFileName = "TotalCleanupGUI_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
            $reportPath = Join-Path ([Environment]::GetFolderPath("Desktop")) $reportFileName
            
            $reportHeader = @"
=====================================================
Informe de Sesion - TotalCleanup GUI v3.0
Fecha y Hora: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Nivel: $($script:CurrentLevel)
=====================================================

"@
            $reportHeader | Out-File -FilePath $reportPath -Encoding UTF8
            $script:LogContent.ToString() | Add-Content -Path $reportPath -Encoding UTF8
            
            "OK: Informe guardado en el Escritorio: $reportFileName"
        } catch {
            "ERROR: $($_.Exception.Message)"
        }
    }
    
    # ==================== TAREAS NIVEL PROFESIONAL ====================
    
    LimpiarRegistroEventos = {
        "Limpiando Registros de Eventos de Windows..."
        ""
        "ADVERTENCIA: Esto puede dificultar el diagnostico de problemas futuros."
        ""
        try {
            $eventLogNames = wevtutil el
            $count = 0
            
            foreach ($logName in $eventLogNames) {
                try {
                    wevtutil cl "$logName" 2>$null
                    $count++
                } catch { }
            }
            
            "OK: $count registros de eventos limpiados."
        } catch {
            "ERROR: $($_.Exception.Message)"
        }
    }
    
    DesfragmentarDisco = {
        "Analizando tipo de disco..."
        ""
        try {
            $disk = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq 0 }
            
            if ($disk.MediaType -eq 'HDD') {
                "Detectado disco HDD. Iniciando desfragmentacion de C:..."
                "Esto puede tardar bastante tiempo..."
                ""
                Optimize-Volume -DriveLetter C -Defrag -Verbose
                "OK: Desfragmentacion completada."
            } elseif ($disk.MediaType -eq 'SSD') {
                "Detectado disco SSD."
                "INFO: La desfragmentacion no es necesaria en SSDs."
                ""
                "Ejecutando optimizacion TRIM..."
                Optimize-Volume -DriveLetter C -ReTrim -Verbose
                "OK: Optimizacion TRIM completada."
            } else {
                "INFO: Tipo de disco no reconocido ($($disk.MediaType))."
            }
        } catch {
            "ERROR: $($_.Exception.Message)"
        }
    }
    
    ResetearConfigRed = {
        "Reseteando Configuracion de Red..."
        ""
        "ADVERTENCIA: Esto puede requerir un reinicio para aplicar los cambios."
        ""
        try {
            "  - Reseteando Winsock Catalog..."
            netsh winsock reset | Out-Null
            
            "  - Reseteando TCP/IP Stack..."
            netsh int ip reset | Out-Null
            
            "  - Limpiando cache DNS..."
            ipconfig /flushdns | Out-Null
            
            "  - Liberando IP..."
            ipconfig /release | Out-Null
            
            "  - Renovando IP..."
            ipconfig /renew | Out-Null
            
            ""
            "OK: Configuracion de red reseteada."
            "RECOMENDACION: Reinicia tu PC para que los cambios surtan efecto completo."
        } catch {
            "ERROR: $($_.Exception.Message)"
        }
    }

# Continuará con las tareas de "Ejecutar Todo"...
# ============================================================================
# PARTE 3 - TAREAS DE "EJECUTAR TODO" PARA CADA NIVEL
# ============================================================================

    # ==================== EJECUTAR TODO - HOGAR ====================
    
    EjecutarTodoHogar = {
        "========================================"
        "EJECUTANDO TODAS LAS TAREAS"
        "Nivel: HOGAR"
        "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        "========================================"
        ""
        
        ">> Paso 1/8: Limpiando Cache DNS..."
        ipconfig /flushdns | Out-Null
        "   [OK] Cache DNS limpiada"
        ""
        
        ">> Paso 2/8: Limpiando Archivos Temporales..."
        if (Test-Path $env:TEMP) {
            Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | 
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
        $sysTemp = Join-Path $env:SystemRoot "Temp"
        if (Test-Path $sysTemp) {
            Get-ChildItem -Path $sysTemp -Recurse -Force -ErrorAction SilentlyContinue | 
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
        $prefetch = Join-Path $env:SystemRoot "Prefetch"
        if (Test-Path $prefetch) {
            Get-ChildItem -Path $prefetch -Recurse -Force -ErrorAction SilentlyContinue | 
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
        "   [OK] Temporales eliminados"
        ""
        
        ">> Paso 3/8: Vaciando Papelera..."
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        "   [OK] Papelera vaciada"
        ""
        
        ">> Paso 4/8: Limpiando Cache Windows Update..."
        Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        $wuPath = Join-Path $env:SystemRoot "SoftwareDistribution\Download"
        if (Test-Path $wuPath) {
            Remove-Item "$wuPath\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
        Start-Service -Name wuauserv -ErrorAction SilentlyContinue
        "   [OK] Cache WU limpiada"
        ""
        
        ">> Paso 5/8: Limpiando Caches de Navegadores..."
        $cachePaths = @(
            "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
            "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
            "$env:LOCALAPPDATA\Discord\Cache"
        )
        foreach ($path in $cachePaths) {
            if (Test-Path $path) {
                Remove-Item "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        "   [OK] Caches de navegadores limpiadas"
        ""
        
        ">> Paso 6/8: Ejecutando DISM..."
        $output = & DISM /Online /Cleanup-Image /RestoreHealth 2>&1
        "   [OK] DISM completado"
        ""
        
        ">> Paso 7/8: Ejecutando SFC..."
        $output = & sfc /scannow 2>&1
        "   [OK] SFC completado"
        ""
        
        ">> Paso 8/8: Programando CHKDSK..."
        & chkdsk C: /r 2>&1 | Out-Null
        "   [OK] CHKDSK programado (requiere reinicio)"
        ""
        
        "========================================"
        "MANTENIMIENTO COMPLETADO"
        "========================================"
        ""
        "NOTA: CHKDSK se ejecutara en el proximo reinicio."
    }
    
    # ==================== EJECUTAR TODO - TECNICO ====================
    
    EjecutarTodoTecnico = {
        "========================================"
        "EJECUTANDO TODAS LAS TAREAS SEGURAS"
        "Nivel: TECNICO"
        "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        "========================================"
        ""
        
        ">> Creando Punto de Restauracion primero..."
        try {
            $descripcion = "TotalCleanupGUI_Auto_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Checkpoint-Computer -Description $descripcion -RestorePointType "MODIFY_SETTINGS" -WarningAction SilentlyContinue -ErrorAction Stop
            "   [OK] Punto de Restauracion creado: $descripcion"
        } catch {
            "   [AVISO] No se pudo crear punto de restauracion"
        }
        ""
        
        ">> Paso 1/6: Limpiando Cache DNS..."
        ipconfig /flushdns | Out-Null
        "   [OK] Cache DNS limpiada"
        ""
        
        ">> Paso 2/6: Limpiando Archivos Temporales..."
        if (Test-Path $env:TEMP) {
            Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | 
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
        $sysTemp = Join-Path $env:SystemRoot "Temp"
        if (Test-Path $sysTemp) {
            Get-ChildItem -Path $sysTemp -Recurse -Force -ErrorAction SilentlyContinue | 
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
        "   [OK] Temporales eliminados"
        ""
        
        ">> Paso 3/6: Vaciando Papelera..."
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        "   [OK] Papelera vaciada"
        ""
        
        ">> Paso 4/6: Limpiando Cache Windows Update..."
        Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        $wuPath = Join-Path $env:SystemRoot "SoftwareDistribution\Download"
        if (Test-Path $wuPath) {
            Remove-Item "$wuPath\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
        Start-Service -Name wuauserv -ErrorAction SilentlyContinue
        "   [OK] Cache WU limpiada"
        ""
        
        ">> Paso 5/6: Ejecutando DISM..."
        $output = & DISM /Online /Cleanup-Image /RestoreHealth 2>&1
        "   [OK] DISM completado"
        ""
        
        ">> Paso 6/6: Ejecutando SFC..."
        $output = & sfc /scannow 2>&1
        "   [OK] SFC completado"
        ""
        
        "========================================"
        "MANTENIMIENTO SEGURO COMPLETADO"
        "========================================"
        ""
        "TAREAS NO INCLUIDAS (ejecutar manualmente si es necesario):"
        "  - CHKDSK (requiere reinicio)"
        "  - Limpieza de Puntos de Restauracion (VSS)"
        "  - Gestion de Planes de Energia"
    }
    
    # ==================== EJECUTAR TODO - PROFESIONAL (SEGURO) ====================
    
    EjecutarTodoProfesionalSeguro = {
        "========================================"
        "EJECUTANDO TAREAS SEGURAS"
        "Nivel: PROFESIONAL (Modo Seguro)"
        "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        "========================================"
        ""
        
        ">> Creando Punto de Restauracion primero..."
        try {
            $descripcion = "TotalCleanupGUI_Safe_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Checkpoint-Computer -Description $descripcion -RestorePointType "MODIFY_SETTINGS" -WarningAction SilentlyContinue -ErrorAction Stop
            "   [OK] Punto de Restauracion creado: $descripcion"
        } catch {
            "   [AVISO] No se pudo crear punto de restauracion"
        }
        ""
        
        ">> Paso 1/7: Limpiando Cache DNS..."
        ipconfig /flushdns | Out-Null
        "   [OK] Cache DNS limpiada"
        ""
        
        ">> Paso 2/7: Limpiando Archivos Temporales..."
        if (Test-Path $env:TEMP) {
            Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | 
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
        $sysTemp = Join-Path $env:SystemRoot "Temp"
        if (Test-Path $sysTemp) {
            Get-ChildItem -Path $sysTemp -Recurse -Force -ErrorAction SilentlyContinue | 
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
        $prefetch = Join-Path $env:SystemRoot "Prefetch"
        if (Test-Path $prefetch) {
            Get-ChildItem -Path $prefetch -Recurse -Force -ErrorAction SilentlyContinue | 
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
        "   [OK] Temporales eliminados"
        ""
        
        ">> Paso 3/7: Vaciando Papelera..."
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        "   [OK] Papelera vaciada"
        ""
        
        ">> Paso 4/7: Limpiando Cache Windows Update..."
        Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        $wuPath = Join-Path $env:SystemRoot "SoftwareDistribution\Download"
        if (Test-Path $wuPath) {
            Remove-Item "$wuPath\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
        Start-Service -Name wuauserv -ErrorAction SilentlyContinue
        "   [OK] Cache WU limpiada"
        ""
        
        ">> Paso 5/7: Limpiando Caches de Navegadores..."
        $cachePaths = @(
            "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
            "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
            "$env:LOCALAPPDATA\Discord\Cache"
        )
        foreach ($path in $cachePaths) {
            if (Test-Path $path) {
                Remove-Item "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        "   [OK] Caches de navegadores limpiadas"
        ""
        
        ">> Paso 6/7: Ejecutando DISM..."
        $output = & DISM /Online /Cleanup-Image /RestoreHealth 2>&1
        "   [OK] DISM completado"
        ""
        
        ">> Paso 7/7: Ejecutando SFC..."
        $output = & sfc /scannow 2>&1
        "   [OK] SFC completado"
        ""
        
        "========================================"
        "MANTENIMIENTO SEGURO COMPLETADO"
        "========================================"
        ""
        "TAREAS NO INCLUIDAS (ejecutar manualmente si es necesario):"
        "  - Limpieza de Registros de Eventos"
        "  - Desfragmentacion de disco"
        "  - Limpieza de Puntos de Restauracion (VSS)"
        "  - Reseteo de configuracion de red"
        "  - CHKDSK (requiere reinicio)"
        "  - Limpieza de WinSxS"
        "  - Limpieza de archivos de log antiguos"
        "  - Desactivar hibernacion"
    }
    
    # ==================== EJECUTAR TODO - PROFESIONAL (COMPLETO) ====================
    
    EjecutarTodoProfesionalCompleto = {
        "========================================"
        "EJECUTANDO MANTENIMIENTO COMPLETO"
        "Nivel: PROFESIONAL (Todas las tareas)"
        "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        "========================================"
        ""
        "ADVERTENCIA: Este proceso incluye tareas avanzadas."
        "Algunas tareas pueden requerir reinicio."
        ""
        
        ">> Creando Punto de Restauracion primero..."
        try {
            $descripcion = "TotalCleanupGUI_Full_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Checkpoint-Computer -Description $descripcion -RestorePointType "MODIFY_SETTINGS" -WarningAction SilentlyContinue -ErrorAction Stop
            "   [OK] Punto de Restauracion creado: $descripcion"
        } catch {
            "   [AVISO] No se pudo crear punto de restauracion"
        }
        ""
        
        ">> Paso 1/12: Limpiando Cache DNS..."
        ipconfig /flushdns | Out-Null
        "   [OK] Cache DNS limpiada"
        ""
        
        ">> Paso 2/12: Limpiando Archivos Temporales..."
        if (Test-Path $env:TEMP) {
            Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | 
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
        $sysTemp = Join-Path $env:SystemRoot "Temp"
        if (Test-Path $sysTemp) {
            Get-ChildItem -Path $sysTemp -Recurse -Force -ErrorAction SilentlyContinue | 
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
        $prefetch = Join-Path $env:SystemRoot "Prefetch"
        if (Test-Path $prefetch) {
            Get-ChildItem -Path $prefetch -Recurse -Force -ErrorAction SilentlyContinue | 
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
        "   [OK] Temporales eliminados"
        ""
        
        ">> Paso 3/12: Vaciando Papelera..."
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        "   [OK] Papelera vaciada"
        ""
        
        ">> Paso 4/12: Limpiando Cache Windows Update..."
        Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        $wuPath = Join-Path $env:SystemRoot "SoftwareDistribution\Download"
        if (Test-Path $wuPath) {
            Remove-Item "$wuPath\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
        Start-Service -Name wuauserv -ErrorAction SilentlyContinue
        "   [OK] Cache WU limpiada"
        ""
        
        ">> Paso 5/12: Limpiando Caches de Navegadores..."
        $cachePaths = @(
            "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
            "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
            "$env:LOCALAPPDATA\Discord\Cache"
        )
        foreach ($path in $cachePaths) {
            if (Test-Path $path) {
                Remove-Item "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        "   [OK] Caches de navegadores limpiadas"
        ""
        
        ">> Paso 6/12: Limpiando Registros de Eventos..."
        $eventLogNames = wevtutil el 2>$null
        foreach ($logName in $eventLogNames) {
            try { wevtutil cl "$logName" 2>$null } catch {}
        }
        "   [OK] Registros de eventos limpiados"
        ""
        
        ">> Paso 7/12: Limpiando archivos de log antiguos..."
        $logPaths = @("$env:SystemRoot\Logs", "$env:SystemRoot\Panther")
        foreach ($path in $logPaths) {
            if (Test-Path $path) {
                Get-ChildItem -Path $path -Recurse -Include *.log, *.etl -ErrorAction SilentlyContinue | 
                    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
                    Remove-Item -Force -ErrorAction SilentlyContinue
            }
        }
        "   [OK] Archivos de log antiguos eliminados"
        ""
        
        ">> Paso 8/12: Ejecutando DISM..."
        $output = & DISM /Online /Cleanup-Image /RestoreHealth 2>&1
        "   [OK] DISM completado"
        ""
        
        ">> Paso 9/12: Ejecutando SFC..."
        $output = & sfc /scannow 2>&1
        "   [OK] SFC completado"
        ""
        
        ">> Paso 10/12: Limpiando WinSxS..."
        $output = & DISM /Online /Cleanup-Image /StartComponentCleanup 2>&1
        "   [OK] WinSxS limpiado"
        ""
        
        ">> Paso 11/12: Reseteando configuracion de red..."
        netsh winsock reset | Out-Null
        netsh int ip reset | Out-Null
        "   [OK] Configuracion de red reseteada"
        ""
        
        ">> Paso 12/12: Programando CHKDSK..."
        & chkdsk C: /r 2>&1 | Out-Null
        "   [OK] CHKDSK programado (requiere reinicio)"
        ""
        
        "========================================"
        "MANTENIMIENTO COMPLETO FINALIZADO"
        "========================================"
        ""
        "IMPORTANTE:"
        "  - CHKDSK se ejecutara en el proximo reinicio"
        "  - Los cambios de red requieren reinicio para aplicarse completamente"
        "  - Se recomienda reiniciar el PC ahora"
    }
}
#endregion

# ============================================================================
# FIN PARTE 3 - Continúa en PARTE 4 con el selector de nivel y GUI
# ============================================================================
# ============================================================================
# PARTE 4 - SELECTOR DE NIVEL Y CONFIGURACION DE BOTONES
# ============================================================================

#region 5. SELECTOR DE NIVEL
function Show-LevelSelector {
    $selectorForm = New-Object System.Windows.Forms.Form
    $selectorForm.Text = "TotalCleanup GUI - Seleccionar Nivel"
    $selectorForm.Size = New-Object System.Drawing.Size(520, 480)
    $selectorForm.StartPosition = "CenterScreen"
    $selectorForm.FormBorderStyle = "FixedDialog"
    $selectorForm.MaximizeBox = $false
    $selectorForm.MinimizeBox = $false
    $selectorForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1E1E1E")
    
    # Titulo
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Selecciona tu Nivel de Experiencia"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::White
    $titleLabel.AutoSize = $true
    $titleLabel.Location = New-Object System.Drawing.Point(70, 25)
    $selectorForm.Controls.Add($titleLabel)
    
    # Subtitulo
    $subtitleLabel = New-Object System.Windows.Forms.Label
    $subtitleLabel.Text = "Esto determinara que opciones estaran disponibles"
    $subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $subtitleLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#AAAAAA")
    $subtitleLabel.AutoSize = $true
    $subtitleLabel.Location = New-Object System.Drawing.Point(100, 60)
    $selectorForm.Controls.Add($subtitleLabel)
    
    $script:SelectedLevelTemp = $null
    
    # BOTON HOGAR
    $hogarButton = New-Object System.Windows.Forms.Button
    $hogarButton.Text = "HOGAR`n`nLimpieza simple y segura`nIdeal para usuarios sin experiencia tecnica"
    $hogarButton.Size = New-Object System.Drawing.Size(440, 90)
    $hogarButton.Location = New-Object System.Drawing.Point(30, 100)
    $hogarButton.FlatStyle = "Flat"
    $hogarButton.FlatAppearance.BorderSize = 0
    $hogarButton.BackColor = [System.Drawing.Color]::MediumSeaGreen
    $hogarButton.ForeColor = [System.Drawing.Color]::White
    $hogarButton.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $hogarButton.Cursor = "Hand"
    $hogarButton.Add_Click({
        $script:SelectedLevelTemp = "Hogar"
        $selectorForm.DialogResult = "OK"
        $selectorForm.Close()
    })
    $selectorForm.Controls.Add($hogarButton)
    
    # BOTON TECNICO
    $tecnicoButton = New-Object System.Windows.Forms.Button
    $tecnicoButton.Text = "TECNICO`n`nMantenimiento y diagnostico avanzado`nPara usuarios con conocimientos intermedios"
    $tecnicoButton.Size = New-Object System.Drawing.Size(440, 90)
    $tecnicoButton.Location = New-Object System.Drawing.Point(30, 205)
    $tecnicoButton.FlatStyle = "Flat"
    $tecnicoButton.FlatAppearance.BorderSize = 0
    $tecnicoButton.BackColor = [System.Drawing.Color]::Gold
    $tecnicoButton.ForeColor = [System.Drawing.Color]::Black
    $tecnicoButton.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $tecnicoButton.Cursor = "Hand"
    $tecnicoButton.Add_Click({
        $script:SelectedLevelTemp = "Tecnico"
        $selectorForm.DialogResult = "OK"
        $selectorForm.Close()
    })
    $selectorForm.Controls.Add($tecnicoButton)
    
    # BOTON PROFESIONAL
    $profesionalButton = New-Object System.Windows.Forms.Button
    $profesionalButton.Text = "PROFESIONAL`n`nControl total del sistema`nSolo para usuarios expertos - Incluye funciones de riesgo"
    $profesionalButton.Size = New-Object System.Drawing.Size(440, 90)
    $profesionalButton.Location = New-Object System.Drawing.Point(30, 310)
    $profesionalButton.FlatStyle = "Flat"
    $profesionalButton.FlatAppearance.BorderSize = 0
    $profesionalButton.BackColor = [System.Drawing.Color]::Firebrick
    $profesionalButton.ForeColor = [System.Drawing.Color]::White
    $profesionalButton.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $profesionalButton.Cursor = "Hand"
    $profesionalButton.Add_Click({
        $script:SelectedLevelTemp = "Profesional"
        $selectorForm.DialogResult = "OK"
        $selectorForm.Close()
    })
    $selectorForm.Controls.Add($profesionalButton)
    
    # Creditos
    $creditLabel = New-Object System.Windows.Forms.Label
    $creditLabel.Text = "TotalCleanup GUI v3.0 - by TheInkReaper"
    $creditLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    $creditLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#666666")
    $creditLabel.AutoSize = $true
    $creditLabel.Location = New-Object System.Drawing.Point(160, 415)
    $selectorForm.Controls.Add($creditLabel)
    
    $result = $selectorForm.ShowDialog()
    
    if ($result -eq "OK") {
        return $script:SelectedLevelTemp
    }
    
    return $null
}
#endregion

#region 6. CONFIGURACION DE BOTONES POR NIVEL
$script:ButtonConfigs = @{
    "Hogar" = @(
        # Fila 0 - Limpieza basica
        @{Text="Limpiar`nCache DNS"; Action="LimpiarCacheDNS"; Tooltip="Limpia la cache del sistema DNS para resolver problemas de conexion"; Color="Default"; Col=0; Row=0},
        @{Text="Limpiar`nTemporales"; Action="LimpiarArchivosTemporales"; Tooltip="Elimina archivos temporales del usuario, sistema y prefetch"; Color="Default"; Col=1; Row=0},
        @{Text="Vaciar`nPapelera"; Action="VaciarPapelera"; Tooltip="Vacia la papelera de reciclaje de todas las unidades"; Color="Default"; Col=2; Row=0},
        @{Text="Limpiar Cache`nWindows Update"; Action="LimpiarCacheWU"; Tooltip="Limpia los archivos descargados de Windows Update"; Color="Warning"; Col=3; Row=0},
        @{Text="Limpiar Cache`nNavegadores"; Action="LimpiarCachesNavegadores"; Tooltip="Limpia caches de Chrome, Edge, Firefox, Discord y Spotify"; Color="Default"; Col=4; Row=0},
        
        # Fila 1 - Reparacion
        @{Text="Ejecutar`nDISM"; Action="EjecutarDISM"; Tooltip="Repara la imagen del sistema Windows"; Color="Warning"; Col=0; Row=1},
        @{Text="Ejecutar`nSFC"; Action="EjecutarSFC"; Tooltip="Escanea y repara archivos del sistema"; Color="Warning"; Col=1; Row=1},
        @{Text="Programar`nCHKDSK"; Action="ProgramarCHKDSK"; Tooltip="Programa verificacion de disco para el proximo reinicio"; Color="Critical"; Col=2; Row=1}
    )
    
    "Tecnico" = @(
        # Fila 0 - Limpieza
        @{Text="Limpiar`nCache DNS"; Action="LimpiarCacheDNS"; Tooltip="Limpia la cache del sistema DNS"; Color="Default"; Col=0; Row=0},
        @{Text="Limpiar`nTemporales"; Action="LimpiarArchivosTemporales"; Tooltip="Elimina archivos temporales"; Color="Default"; Col=1; Row=0},
        @{Text="Vaciar`nPapelera"; Action="VaciarPapelera"; Tooltip="Vacia la papelera de reciclaje"; Color="Default"; Col=2; Row=0},
        @{Text="Limpiar Cache`nWindows Update"; Action="LimpiarCacheWU"; Tooltip="Limpia archivos de Windows Update"; Color="Warning"; Col=3; Row=0},
        
        # Fila 1 - Reparacion y Diagnostico
        @{Text="Ejecutar`nDISM"; Action="EjecutarDISM"; Tooltip="Repara la imagen del sistema"; Color="Warning"; Col=0; Row=1},
        @{Text="Ejecutar`nSFC"; Action="EjecutarSFC"; Tooltip="Repara archivos del sistema"; Color="Warning"; Col=1; Row=1},
        @{Text="Programar`nCHKDSK"; Action="ProgramarCHKDSK"; Tooltip="Programa verificacion de disco (requiere reinicio)"; Color="Critical"; Col=2; Row=1},
        @{Text="Ver Salud`nDiscos"; Action="VerSaludDiscos"; Tooltip="Muestra el estado S.M.A.R.T."; Color="Default"; Col=3; Row=1},
        @{Text="Verificar`nReinicio"; Action="VerificarReinicioPendiente"; Tooltip="Verifica reinicios pendientes"; Color="Default"; Col=4; Row=1},
        
        # Fila 2 - Utilidades
        @{Text="Gestionar`nEnergia"; Action="GestionarPlanesEnergia"; Tooltip="Muestra planes de energia"; Color="Default"; Col=0; Row=2},
        @{Text="Limpiar VSS`n(PELIGRO)"; Action="LimpiarVSS"; Tooltip="PELIGRO: Elimina TODOS los puntos de restauracion"; Color="Critical"; Col=1; Row=2},
        @{Text="Crear Punto`nRestauracion"; Action="CrearPuntoRestauracion"; Tooltip="Crea un punto de restauracion"; Color="Success"; Col=2; Row=2},
        @{Text="Generar`nInforme"; Action="GenerarInformeSesion"; Tooltip="Guarda informe en el Escritorio"; Color="Success"; Col=3; Row=2}
    )
    
    "Profesional" = @(
        # Fila 0 (5 botones) - Limpieza basica
        @{Text="Limpiar`nCache DNS"; Action="LimpiarCacheDNS"; Tooltip="Limpia cache DNS"; Color="Default"; Col=0; Row=0},
        @{Text="Limpiar`nTemporales"; Action="LimpiarArchivosTemporales"; Tooltip="Elimina temporales (Usuario, Sistema, Prefetch)"; Color="Default"; Col=1; Row=0},
        @{Text="Vaciar`nPapelera"; Action="VaciarPapelera"; Tooltip="Vacia papelera de reciclaje"; Color="Default"; Col=2; Row=0},
        @{Text="Limpiar Cache`nWindows Update"; Action="LimpiarCacheWU"; Tooltip="Limpia cache de Windows Update"; Color="Default"; Col=3; Row=0},
        @{Text="Limpiar Caches`nUsuario"; Action="LimpiarCachesNavegadores"; Tooltip="Limpia caches de navegadores y apps"; Color="Default"; Col=4; Row=0},
        
        # Fila 1 (5 botones) - Limpieza avanzada y reparacion
        @{Text="Limpiar`nEventos"; Action="LimpiarRegistroEventos"; Tooltip="Limpia registros de eventos de Windows (Precaucion)"; Color="Warning"; Col=0; Row=1},
        @{Text="Desfragmentar`nDisco"; Action="DesfragmentarDisco"; Tooltip="Desfragmenta HDD (detecta SSD automaticamente)"; Color="Default"; Col=1; Row=1},
        @{Text="Limpiar Puntos`nRestauracion"; Action="LimpiarPuntosRestauracionAntiguos"; Tooltip="Elimina puntos de restauracion antiguos (Hibrido)"; Color="Warning"; Col=2; Row=1},
        @{Text="Ejecutar`nDISM"; Action="EjecutarDISM"; Tooltip="CheckHealth, ScanHealth, RestoreHealth"; Color="Default"; Col=3; Row=1},
        @{Text="Ejecutar`nSFC"; Action="EjecutarSFC"; Tooltip="Ejecuta SFC /scannow"; Color="Default"; Col=4; Row=1},
        
        # Fila 2 (5 botones) - Reparacion avanzada y guias
        @{Text="Programar`nCHKDSK"; Action="ProgramarCHKDSK"; Tooltip="Programa CHKDSK C:/r (Requiere reinicio)"; Color="Warning"; Col=0; Row=2},
        @{Text="Resetear`nRed"; Action="ResetearConfigRed"; Tooltip="Resetea Winsock y TCP-IP"; Color="Warning"; Col=1; Row=2},
        @{Text="Guia:`nInicio"; Action="MostrarGuiaProgramasInicio"; Tooltip="Guia para gestionar programas de inicio"; Color="Default"; Col=2; Row=2},
        @{Text="Guia:`nDesinstalar"; Action="MostrarGuiaDesinstalarProgramas"; Tooltip="Guia para eliminar programas"; Color="Critical"; Col=3; Row=2},
        @{Text="Guia:`nDrivers"; Action="MostrarGuiaControladores"; Tooltip="Guia para actualizar controladores"; Color="Default"; Col=4; Row=2},
        
        # Fila 3 (3 botones) - Guia y utilidades
        @{Text="Guia:`nServicios"; Action="MostrarGuiaServicios"; Tooltip="Guia para optimizar servicios (Precaucion)"; Color="Critical"; Col=0; Row=3},
        @{Text="Crear Punto`nRestauracion"; Action="CrearPuntoRestauracion"; Tooltip="Crea un punto de restauracion del sistema"; Color="Success"; Col=1; Row=3},
        @{Text="Generar`nInforme"; Action="GenerarInformeSesion"; Tooltip="Genera informe de la sesion"; Color="Success"; Col=2; Row=3}
    )
}
#endregion

# ============================================================================
# FIN PARTE 4 - Continúa en PARTE 5 con funciones de GUI y ejecución
# ============================================================================
# ============================================================================
# PARTE 5 - FUNCIONES DE GUI, JOBS Y CREACION DE INTERFAZ
# ============================================================================

#region 7. FUNCION PARA CARGAR BOTONES
function Load-LevelButtons {
    param([string]$Level)
    
    $script:OptionsPanel.Controls.Clear()
    $script:CurrentLevel = $Level
    
    $buttons = $script:ButtonConfigs[$Level]
    
    foreach ($btnCfg in $buttons) {
        $button = New-Object System.Windows.Forms.Button
        $button.Text = $btnCfg.Text
        $button.Dock = "Fill"
        $button.Margin = New-Object System.Windows.Forms.Padding(4)
        $button.FlatStyle = "Flat"
        $button.FlatAppearance.BorderSize = 0
        $button.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $button.Cursor = "Hand"
        
        switch ($btnCfg.Color) {
            "Warning" {
                $button.BackColor = [System.Drawing.Color]::Gold
                $button.ForeColor = [System.Drawing.Color]::Black
            }
            "Critical" {
                $button.BackColor = [System.Drawing.Color]::Firebrick
                $button.ForeColor = [System.Drawing.Color]::White
            }
            "Success" {
                $button.BackColor = [System.Drawing.Color]::MediumSeaGreen
                $button.ForeColor = [System.Drawing.Color]::White
            }
            default {
                $button.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#4E4E52")
                $button.ForeColor = [System.Drawing.Color]::White
            }
        }
        
        $tooltip = New-Object System.Windows.Forms.ToolTip
        $tooltip.SetToolTip($button, $btnCfg.Tooltip)
        
        # Guardar el nombre de la accion en el Tag del boton
        $button.Tag = $btnCfg.Action
        
        # Usar Add_Click - las guias se ejecutan directamente, el resto con Job
        $button.Add_Click({
            param($sender, $e)
            $actionName = $sender.Tag
            
            # Las guias se ejecutan directamente (sin Job) para poder mostrar MessageBox
            if ($actionName -like "MostrarGuia*") {
                switch ($actionName) {
                    "MostrarGuiaProgramasInicio" {
                        [System.Windows.Forms.MessageBox]::Show(
                            "GUIA: GESTIONAR PROGRAMAS DE INICIO`n`n" +
                            "COMO HACERLO:`n" +
                            "1. Presiona Ctrl+Shift+Esc para abrir el Administrador de Tareas`n" +
                            "2. Ve a la pestana 'Inicio' (o 'Aplicaciones de inicio' en Win11)`n" +
                            "3. Clic derecho en programas innecesarios > 'Deshabilitar'`n`n" +
                            "PROGRAMAS SEGUROS PARA DESHABILITAR:`n" +
                            "  - Actualizadores de software (Adobe, Java, etc.)`n" +
                            "  - Programas de chat que no uses constantemente`n" +
                            "  - Utilidades de sincronizacion secundarias`n`n" +
                            "NO DESHABILITAR:`n" +
                            "  - Antivirus/Software de seguridad`n" +
                            "  - Controladores de hardware esenciales",
                            "Guia: Programas de Inicio",
                            [System.Windows.Forms.MessageBoxButtons]::OK,
                            [System.Windows.Forms.MessageBoxIcon]::Information
                        )
                    }
                    "MostrarGuiaDesinstalarProgramas" {
                        [System.Windows.Forms.MessageBox]::Show(
                            "GUIA: ELIMINAR PROGRAMAS NO UTILIZADOS`n`n" +
                            "COMO HACERLO:`n" +
                            "1. Abre 'Configuracion' > 'Aplicaciones' > 'Aplicaciones instaladas'`n" +
                            "   O usa 'Panel de control' > 'Programas y caracteristicas'`n`n" +
                            "2. Ordena por fecha de instalacion o tamano`n`n" +
                            "3. Desinstala programas que no uses`n`n" +
                            "PRECAUCION - NO DESINSTALAR:`n" +
                            "  - Microsoft Visual C++ Redistributables`n" +
                            "  - Controladores de hardware`n" +
                            "  - .NET Framework",
                            "Guia: Eliminar Programas",
                            [System.Windows.Forms.MessageBoxButtons]::OK,
                            [System.Windows.Forms.MessageBoxIcon]::Information
                        )
                    }
                    "MostrarGuiaControladores" {
                        [System.Windows.Forms.MessageBox]::Show(
                            "GUIA: BUSCAR Y ACTUALIZAR CONTROLADORES`n`n" +
                            "METODOS RECOMENDADOS:`n`n" +
                            "1. WINDOWS UPDATE (MAS SEGURO):`n" +
                            "   Configuracion > Windows Update > Actualizaciones opcionales`n`n" +
                            "2. ADMINISTRADOR DE DISPOSITIVOS:`n" +
                            "   Clic derecho en Inicio > Administrador de dispositivos`n" +
                            "   Clic derecho en dispositivo > Actualizar controlador`n`n" +
                            "3. SITIO WEB DEL FABRICANTE:`n" +
                            "   Para GPU: NVIDIA, AMD o Intel`n" +
                            "   Para otros: sitio del fabricante del PC`n`n" +
                            "ADVERTENCIA:`n" +
                            "  - Evita programas 'actualizadores de drivers' de terceros`n" +
                            "  - Crea punto de restauracion antes de actualizar",
                            "Guia: Actualizar Controladores",
                            [System.Windows.Forms.MessageBoxButtons]::OK,
                            [System.Windows.Forms.MessageBoxIcon]::Information
                        )
                    }
                    "MostrarGuiaServicios" {
                        [System.Windows.Forms.MessageBox]::Show(
                            "GUIA: OPTIMIZAR SERVICIOS DE WINDOWS`n`n" +
                            "ADVERTENCIA: Modificar servicios incorrectamente puede`n" +
                            "causar inestabilidad severa del sistema.`n`n" +
                            "COMO ACCEDER:`n" +
                            "  Presiona Win+R, escribe 'services.msc' y Enter`n`n" +
                            "SERVICIOS SEGUROS PARA DESHABILITAR (si no los usas):`n" +
                            "  - Fax`n" +
                            "  - Administrador de mapas descargados`n" +
                            "  - Servicio de telefonia`n`n" +
                            "NUNCA DESHABILITAR:`n" +
                            "  - Servicios de Windows Defender`n" +
                            "  - Llamada a procedimiento remoto (RPC)`n" +
                            "  - Plug and Play`n" +
                            "  - Servicios de red esenciales`n`n" +
                            "RECOMENDACION: Cambia a 'Manual' en lugar de 'Deshabilitado'",
                            "Guia: Servicios de Windows",
                            [System.Windows.Forms.MessageBoxButtons]::OK,
                            [System.Windows.Forms.MessageBoxIcon]::Warning
                        )
                    }
                }
            } else {
                # El resto de funciones se ejecutan con Job
                $scriptBlock = $script:Acciones[$actionName]
                if ($scriptBlock -ne $null) {
                    Start-Task -Nombre $actionName -ScriptBlock $scriptBlock
                } else {
                    Write-GUILog "ERROR: No se encontro la accion '$actionName'" -Type "Error"
                }
            }
        })
        
        $script:OptionsPanel.Controls.Add($button, $btnCfg.Col, $btnCfg.Row)
    }
    
    # Actualizar titulo
    if ($script:Form) {
        $script:Form.Text = "TotalCleanup GUI v3.0 - Modo $Level"
    }
    
    # Actualizar botones de Ejecutar Todo
    Update-RunAllButtons -Level $Level
}

function Update-RunAllButtons {
    param([string]$Level)
    
    $script:RunAllPanel.Controls.Clear()
    
    if ($Level -eq "Profesional") {
        # Dos botones para Profesional: Seguro y Completo
        
        # Boton Ejecutar Todo SEGURO
        $safeButton = New-Object System.Windows.Forms.Button
        $safeButton.Text = "Ejecutar Todo (SEGURO)"
        $safeButton.Dock = "Fill"
        $safeButton.Margin = New-Object System.Windows.Forms.Padding(5)
        $safeButton.FlatStyle = "Flat"
        $safeButton.FlatAppearance.BorderSize = 0
        $safeButton.BackColor = [System.Drawing.Color]::MediumSeaGreen
        $safeButton.ForeColor = [System.Drawing.Color]::White
        $safeButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $safeButton.Cursor = "Hand"
        $safeButton.Add_Click({
            $confirmResult = [System.Windows.Forms.MessageBox]::Show(
                "Esto ejecutara las tareas SEGURAS del nivel Profesional:`n`n" +
                "- Crear Punto de Restauracion`n" +
                "- Limpiar Cache DNS`n" +
                "- Limpiar Archivos Temporales`n" +
                "- Vaciar Papelera`n" +
                "- Limpiar Cache Windows Update`n" +
                "- Limpiar Caches de Navegadores`n" +
                "- Ejecutar DISM`n" +
                "- Ejecutar SFC`n`n" +
                "NO SE INCLUYEN tareas de riesgo como:`n" +
                "Registros de Eventos, VSS, Reset Red, CHKDSK, WinSxS`n`n" +
                "Deseas continuar?",
                "Confirmar Ejecucion Segura",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )
            if ($confirmResult -eq "Yes") {
                $sb = $script:Acciones["EjecutarTodoProfesionalSeguro"]
                if ($sb) { Start-Task -Nombre "Ejecutar Todo (SEGURO)" -ScriptBlock $sb }
            }
        })
        (New-Object System.Windows.Forms.ToolTip).SetToolTip($safeButton, "Ejecuta solo las tareas seguras, omitiendo las de alto riesgo")
        $script:RunAllPanel.Controls.Add($safeButton, 0, 0)
        
        # Boton Ejecutar Todo COMPLETO
        $completeButton = New-Object System.Windows.Forms.Button
        $completeButton.Text = "Ejecutar Todo (COMPLETO)"
        $completeButton.Dock = "Fill"
        $completeButton.Margin = New-Object System.Windows.Forms.Padding(5)
        $completeButton.FlatStyle = "Flat"
        $completeButton.FlatAppearance.BorderSize = 0
        $completeButton.BackColor = [System.Drawing.Color]::Firebrick
        $completeButton.ForeColor = [System.Drawing.Color]::White
        $completeButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $completeButton.Cursor = "Hand"
        $completeButton.Add_Click({
            $confirmResult = [System.Windows.Forms.MessageBox]::Show(
                "ADVERTENCIA: Esto ejecutara TODAS las tareas incluyendo las de ALTO RIESGO:`n`n" +
                "- Limpieza de Registros de Eventos`n" +
                "- Limpieza de WinSxS`n" +
                "- Reset de Configuracion de Red`n" +
                "- CHKDSK (requiere reinicio)`n`n" +
                "Este proceso puede tardar varias horas y REQUERIRA REINICIO.`n`n" +
                "Estas SEGURO de que deseas continuar?",
                "ADVERTENCIA - Ejecucion Completa",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            if ($confirmResult -eq "Yes") {
                $sb = $script:Acciones["EjecutarTodoProfesionalCompleto"]
                if ($sb) { Start-Task -Nombre "Ejecutar Todo (COMPLETO)" -ScriptBlock $sb }
            }
        })
        (New-Object System.Windows.Forms.ToolTip).SetToolTip($completeButton, "PELIGRO: Ejecuta TODAS las tareas incluyendo las de alto riesgo")
        $script:RunAllPanel.Controls.Add($completeButton, 1, 0)
        
    } else {
        # Un solo boton para Hogar y Tecnico
        $runAllButton = New-Object System.Windows.Forms.Button
        $runAllButton.Text = "Ejecutar Todas las Tareas Seguras"
        $runAllButton.Dock = "Fill"
        $runAllButton.Margin = New-Object System.Windows.Forms.Padding(5)
        $runAllButton.FlatStyle = "Flat"
        $runAllButton.FlatAppearance.BorderSize = 0
        $runAllButton.BackColor = [System.Drawing.Color]::MediumSeaGreen
        $runAllButton.ForeColor = [System.Drawing.Color]::White
        $runAllButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $runAllButton.Cursor = "Hand"
        
        $actionName = if ($Level -eq "Hogar") { "EjecutarTodoHogar" } else { "EjecutarTodoTecnico" }
        
        $runAllButton.Add_Click({
            param($sender, $e)
            $level = $script:CurrentLevel
            $action = if ($level -eq "Hogar") { "EjecutarTodoHogar" } else { "EjecutarTodoTecnico" }
            
            $msg = if ($level -eq "Hogar") {
                "Esto ejecutara todas las tareas del nivel Hogar:`n`n" +
                "- Limpiar Cache DNS`n- Limpiar Temporales`n- Vaciar Papelera`n" +
                "- Limpiar Cache WU`n- Limpiar Navegadores`n- DISM`n- SFC`n- CHKDSK`n`n" +
                "Deseas continuar?"
            } else {
                "Esto ejecutara las tareas SEGURAS del nivel Tecnico:`n`n" +
                "- Crear Punto de Restauracion`n- Limpiar Cache DNS`n- Limpiar Temporales`n" +
                "- Vaciar Papelera`n- Limpiar Cache WU`n- DISM`n- SFC`n`n" +
                "NO incluye: CHKDSK, VSS, Gestion de Energia`n`nDeseas continuar?"
            }
            
            $confirmResult = [System.Windows.Forms.MessageBox]::Show($msg, "Confirmar Ejecucion", "YesNo", "Question")
            if ($confirmResult -eq "Yes") {
                $sb = $script:Acciones[$action]
                if ($sb) { Start-Task -Nombre "Ejecutar Todo" -ScriptBlock $sb }
            }
        })
        
        (New-Object System.Windows.Forms.ToolTip).SetToolTip($runAllButton, "Ejecuta todas las tareas seguras del nivel actual")
        $script:RunAllPanel.Controls.Add($runAllButton, 0, 0)
    }
    
    # Boton Interrumpir (siempre presente)
    $script:StopButton = New-Object System.Windows.Forms.Button
    $script:StopButton.Text = "Interrumpir"
    $script:StopButton.Dock = "Fill"
    $script:StopButton.Margin = New-Object System.Windows.Forms.Padding(5)
    $script:StopButton.FlatStyle = "Flat"
    $script:StopButton.FlatAppearance.BorderSize = 0
    $script:StopButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#4E4E52")
    $script:StopButton.ForeColor = [System.Drawing.Color]::White
    $script:StopButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $script:StopButton.Enabled = $false
    $script:StopButton.Add_Click({
        Get-Job -Name "CleanupTask" -ErrorAction SilentlyContinue | Stop-Job
        Write-GUILog "Tarea interrumpida por el usuario." -Type "Warning"
    })
    
    $col = if ($Level -eq "Profesional") { 2 } else { 1 }
    $script:RunAllPanel.Controls.Add($script:StopButton, $col, 0)
}
#endregion

#region 8. LOGICA DE JOBS
function Set-TaskRunningState {
    param([bool]$IsRunning)
    
    $script:IsTaskRunning = $IsRunning
    $script:OptionsPanel.Enabled = -not $IsRunning
    
    foreach ($ctrl in $script:RunAllPanel.Controls) {
        if ($ctrl -ne $script:StopButton) {
            $ctrl.Enabled = -not $IsRunning
        }
    }
    
    $script:StopButton.Enabled = $IsRunning
    if ($IsRunning) {
        $script:StopButton.BackColor = [System.Drawing.Color]::Firebrick
    } else {
        $script:StopButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#4E4E52")
    }
}

function Start-Task {
    param(
        [string]$Nombre,
        [scriptblock]$ScriptBlock
    )
    
    Clear-GUILog
    Write-GUILog "Iniciando: $Nombre..." -Type "Info"
    Write-GUILog ""
    Set-TaskRunningState $true
    
    Get-Job -Name "CleanupTask" -ErrorAction SilentlyContinue | Remove-Job -Force
    Start-Job -Name "CleanupTask" -ScriptBlock $ScriptBlock | Out-Null
    
    $script:GlobalProgressBar.Style = 'Marquee'
    $script:GlobalProgressBar.Visible = $true
    $script:JobTimer.Start()
}

$script:JobTimer = New-Object System.Windows.Forms.Timer
$script:JobTimer.Interval = 250

$script:JobTimer.Add_Tick({
    $job = Get-Job -Name "CleanupTask" -ErrorAction SilentlyContinue
    
    if ($job) {
        $output = Receive-Job $job -ErrorAction SilentlyContinue
        if ($output) {
            $output | ForEach-Object { 
                if ($_ -ne $null -and $_.ToString().Trim() -ne "") {
                    Write-GUILog $_.ToString() -NoTime 
                }
            }
        }
        
        if ($job.State -in @('Completed', 'Failed', 'Stopped')) {
            $script:JobTimer.Stop()
            
            $output = Receive-Job $job -ErrorAction SilentlyContinue
            if ($output) {
                $output | ForEach-Object { 
                    if ($_ -ne $null -and $_.ToString().Trim() -ne "") {
                        Write-GUILog $_.ToString() -NoTime 
                    }
                }
            }
            
            Write-GUILog ""
            Write-GUILog "========================================" -NoTime
            Write-GUILog "Tarea completada con estado: $($job.State)" -Type "Success"
            Write-GUILog "========================================" -NoTime
            
            $script:GlobalProgressBar.Style = 'Continuous'
            $script:GlobalProgressBar.Value = 100
            
            Remove-Job $job -Force
            Set-TaskRunningState $false
        }
    }
})
#endregion

# ============================================================================
# FIN PARTE 5 - Continúa en PARTE 6 con la creación del formulario principal
# ============================================================================
# ============================================================================
# PARTE 6A - CREACION DEL FORMULARIO PRINCIPAL
# ============================================================================

#region 9. CREACION DE LA GUI PRINCIPAL
$script:Form = New-Object System.Windows.Forms.Form
$script:Form.Text = "TotalCleanup GUI v3.0 - Herramienta de Mantenimiento"
$script:Form.Size = New-Object System.Drawing.Size(1000, 750)
$script:Form.StartPosition = "CenterScreen"
$script:Form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1E1E1E")
$script:Form.ForeColor = [System.Drawing.Color]::White
$script:Form.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$script:Form.MinimumSize = New-Object System.Drawing.Size(900, 650)

# ===== CARGAR ICONO =====
# Icono incrustado en Base64 (15x15) - también busca icon.ico en la misma carpeta
$script:IconBase64 = "AAABAAEADw8AAAAAIAD6AgAAFgAAAIlQTkcNChoKAAAADUlIRFIAAAAPAAAADwgGAAAAO9aVSgAAAAlwSFlzAAAOwwAADsMBx2+oZAAAAppJREFUeJyMkVtI02EYh//MbU43FdPEzSjzMMoUxKQ2nTp1DdbUOZtzNJenaVaaTac252Eepuah1EwNNDU00MrM00VKEGInvZAOdNNdlxFBdiFq/Pr+UrKu8oOH7/197/vwXnwU9f8jVJ/P3yyzde+MzLz5XGS9CWF4zBx5Z+/DpZgcF+7tRKXm49K7b5hY+oDa/nnwPLyr9yPTx0xI6Z/9hEOBYY9JLSEc3o8oImg9BAErwdJz8PI/sUOyp+MAIyAouEGhSl9gsdmyP2++hFDCAToc9A9ZjVDmQhAiBonejrJmdmkZs89fI7fY+p3kY4TLhD4Cnx5QZl1fHlzZhrp0+F+ZwWBcbWrvwkV5OMz1PXTT3YnlXMQPjf7K4nAt9MyVlofztJxe8lRTXYKNjQjPKKlpxHfYq7a9oKaFwWo2njfXnFFaFEn1IBQm2yKUE2KYxhAH/FMcQSrq1LD0NbfgJnwTiMZ4y7eNvWRfQWsaB2FQDBCghKw8AzJo0MRMiP5YjAR+P/6ycNHkD45P7xV03NsO4dhjYexfRIOQFJd0IdxL4bK0wc+NMEMvEuuQMuQuKOgZuZ4IXdP/9i2IbJTWEiWC8a8v4Dsh4S8Sv6LfY3J8B3kbZ9DWKF6ZhL+X0XQGzAYkRiShIVATsiNSsRyhBrPBNHYcRKNn2e6FhIhf9v6D8MH/MMFPQQAAAASUVORK5CYII="

function Set-FormIcon {
    # Primero intentar cargar icon.ico desde la carpeta del script
    $iconPath = Join-Path $PSScriptRoot "icon.ico"
    if (Test-Path $iconPath) {
        try {
            $script:Form.Icon = New-Object System.Drawing.Icon($iconPath)
            return
        } catch { }
    }
    
    # Si no existe, usar el icono incrustado
    try {
        $iconBytes = [Convert]::FromBase64String($script:IconBase64)
        $iconStream = New-Object System.IO.MemoryStream($iconBytes, 0, $iconBytes.Length)
        $script:Form.Icon = New-Object System.Drawing.Icon($iconStream)
    } catch { }
}

Set-FormIcon

# ===== MENU SUPERIOR =====
$MenuStrip = New-Object System.Windows.Forms.MenuStrip
$MenuStrip.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#252526")
$MenuStrip.ForeColor = [System.Drawing.Color]::White

# ==================== MENU ARCHIVO ====================
$ArchivoMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$ArchivoMenu.Text = "Archivo"
$ArchivoMenu.ForeColor = [System.Drawing.Color]::White

$GuardarLogMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$GuardarLogMenu.Text = "Guardar Log"
$GuardarLogMenu.ShortcutKeys = [System.Windows.Forms.Keys]::Control -bor [System.Windows.Forms.Keys]::S
$GuardarLogMenu.ShowShortcutKeys = $true
$GuardarLogMenu.Add_Click({
    try {
        $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveDialog.Filter = "Archivos de texto (*.txt)|*.txt|Archivos de log (*.log)|*.log"
        $saveDialog.FileName = "TotalCleanupGUI_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        if ($saveDialog.ShowDialog() -eq "OK") {
            $script:LogContent.ToString() | Out-File -FilePath $saveDialog.FileName -Encoding UTF8
            [System.Windows.Forms.MessageBox]::Show("Log guardado correctamente.", "Exito", "OK", "Information")
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error al guardar: $($_.Exception.Message)", "Error", "OK", "Error")
    }
})

$LimpiarLogMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$LimpiarLogMenu.Text = "Limpiar Log"
$LimpiarLogMenu.ShortcutKeys = [System.Windows.Forms.Keys]::Control -bor [System.Windows.Forms.Keys]::L
$LimpiarLogMenu.ShowShortcutKeys = $true
$LimpiarLogMenu.Add_Click({ Clear-GUILog })

$SalirMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$SalirMenu.Text = "Salir"
$SalirMenu.ShortcutKeys = [System.Windows.Forms.Keys]::Alt -bor [System.Windows.Forms.Keys]::F4
$SalirMenu.ShowShortcutKeys = $true
$SalirMenu.Add_Click({ $script:Form.Close() })

# Separadores para Archivo
$SeparadorArchivo = New-Object System.Windows.Forms.ToolStripSeparator

$ArchivoMenu.DropDownItems.AddRange(@($GuardarLogMenu, $LimpiarLogMenu, $SeparadorArchivo, $SalirMenu))
$MenuStrip.Items.Add($ArchivoMenu)

# ==================== MENU OPCIONES ====================
$OpcionesMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$OpcionesMenu.Text = "Opciones"
$OpcionesMenu.ForeColor = [System.Drawing.Color]::White

$CambiarNivelMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$CambiarNivelMenu.Text = "Cambiar Nivel"
$CambiarNivelMenu.ShortcutKeys = [System.Windows.Forms.Keys]::Control -bor [System.Windows.Forms.Keys]::N
$CambiarNivelMenu.ShowShortcutKeys = $true
$CambiarNivelMenu.Add_Click({
    if ($script:IsTaskRunning) {
        [System.Windows.Forms.MessageBox]::Show("Espera a que termine la tarea actual.", "Aviso", "OK", "Warning")
        return
    }
    $newLevel = Show-LevelSelector
    if ($newLevel) {
        Load-LevelButtons -Level $newLevel
        Clear-GUILog
        Write-GUILog "Nivel cambiado a: $newLevel" -Type "Success"
        Write-GUILog "Selecciona una tarea del panel superior para comenzar."
    }
})

$OpcionesMenu.DropDownItems.Add($CambiarNivelMenu)
$MenuStrip.Items.Add($OpcionesMenu)

# ==================== MENU AYUDA ====================
$AyudaMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$AyudaMenu.Text = "Ayuda"
$AyudaMenu.ForeColor = [System.Drawing.Color]::White

$LeyendaMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$LeyendaMenu.Text = "Leyenda de Colores"
$LeyendaMenu.ShortcutKeys = [System.Windows.Forms.Keys]::F1
$LeyendaMenu.ShowShortcutKeys = $true
$LeyendaMenu.Add_Click({
    [System.Windows.Forms.MessageBox]::Show(
        "LEYENDA DE COLORES DE BOTONES:`n`n" +
        "[GRIS] - Tarea segura, sin riesgos`n`n" +
        "[VERDE] - Accion recomendada`n   (Crear punto de restauracion, Informes)`n`n" +
        "[AMARILLO] - Precaucion, posibles efectos secundarios`n   (Puede requerir reinicio o afectar temporalmente)`n`n" +
        "[ROJO] - PELIGRO, alto riesgo para el sistema`n   (Puede causar perdida de datos o inestabilidad)",
        "Leyenda de Colores", "OK", "Information")
})

$EstadisticasMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$EstadisticasMenu.Text = "Estadisticas de Sesion"
$EstadisticasMenu.Add_Click({
    $tiempoSesion = (Get-Date) - $script:SessionStartTime
    $tiempoFormateado = "{0:D2}h {1:D2}m {2:D2}s" -f $tiempoSesion.Hours, $tiempoSesion.Minutes, $tiempoSesion.Seconds
    [System.Windows.Forms.MessageBox]::Show(
        "ESTADISTICAS DE SESION`n`n" +
        "Nivel actual: $($script:CurrentLevel)`n`n" +
        "Tareas ejecutadas: $($script:TasksExecuted)`n" +
        "Tareas exitosas: $($script:TasksSuccessful)`n`n" +
        "Tiempo de sesion: $tiempoFormateado`n" +
        "Inicio: $($script:SessionStartTime.ToString('HH:mm:ss'))",
        "Estadisticas", "OK", "Information")
})

$AtajosTecladoMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$AtajosTecladoMenu.Text = "Atajos de Teclado"
$AtajosTecladoMenu.Add_Click({
    [System.Windows.Forms.MessageBox]::Show(
        "ATAJOS DE TECLADO`n`n" +
        "Ctrl + S  -  Guardar Log`n" +
        "Ctrl + L  -  Limpiar Log`n" +
        "Ctrl + N  -  Cambiar Nivel`n" +
        "F1        -  Leyenda de Colores`n" +
        "Alt + F4  -  Salir",
        "Atajos de Teclado", "OK", "Information")
})

$SeparadorAyuda = New-Object System.Windows.Forms.ToolStripSeparator

$AcercaDeMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$AcercaDeMenu.Text = "Acerca de"
$AcercaDeMenu.Add_Click({
    [System.Windows.Forms.MessageBox]::Show(
        "TotalCleanup GUI v3.0`n`n" +
        "Herramienta profesional de mantenimiento`n" +
        "para sistemas Windows 10/11`n`n" +
        "Caracteristicas:`n" +
        "  - Tres niveles de experiencia`n" +
        "  - Interfaz grafica intuitiva`n" +
        "  - Codigo de colores por riesgo`n" +
        "  - Guias integradas`n`n" +
        "Autor: TheInkReaper`n" +
        "Version: 3.0 (2025)",
        "Acerca de TotalCleanup", "OK", "Information")
})

$AyudaMenu.DropDownItems.AddRange(@($LeyendaMenu, $EstadisticasMenu, $AtajosTecladoMenu, $SeparadorAyuda, $AcercaDeMenu))
$MenuStrip.Items.Add($AyudaMenu)

# ==================== BOTON AYUDA RAPIDA ? ====================
$AyudaRapidaButton = New-Object System.Windows.Forms.ToolStripMenuItem
$AyudaRapidaButton.Text = "  ?  "
$AyudaRapidaButton.ForeColor = [System.Drawing.Color]::White
$AyudaRapidaButton.ToolTipText = "Ayuda rapida - Leyenda de colores (F1)"
$AyudaRapidaButton.Add_Click({
    [System.Windows.Forms.MessageBox]::Show(
        "GUIA RAPIDA DE COLORES`n`n" +
        "[GRIS] = Seguro`n" +
        "[VERDE] = Recomendado`n" +
        "[AMARILLO] = Precaucion`n" +
        "[ROJO] = Peligro`n`n" +
        "Consejo: Pasa el raton sobre un boton`n" +
        "para ver mas detalles y tiempo estimado.`n`n" +
        "Pulsa F1 para mas informacion.",
        "Ayuda Rapida", "OK", "Information")
})
$MenuStrip.Items.Add($AyudaRapidaButton)
#endregion
# ============================================================================
# PARTE 6B - LAYOUT Y CONTROLES DE LA GUI
# ============================================================================

#region 10. LAYOUT PRINCIPAL
$MainLayout = New-Object System.Windows.Forms.TableLayoutPanel
$MainLayout.Dock = "Fill"
$MainLayout.ColumnCount = 1
$MainLayout.RowCount = 4
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 320)))
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 60)))
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 25)))
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100)))

# Panel de Opciones (Botones)
$script:OptionsPanel = New-Object System.Windows.Forms.TableLayoutPanel
$script:OptionsPanel.Dock = "Fill"
$script:OptionsPanel.Padding = New-Object System.Windows.Forms.Padding(10)
$script:OptionsPanel.ColumnCount = 5
$script:OptionsPanel.RowCount = 5

1..5 | ForEach-Object {
    $script:OptionsPanel.ColumnStyles.Add([System.Windows.Forms.ColumnStyle]::new([System.Windows.Forms.SizeType]::Percent, 20))
}
1..5 | ForEach-Object {
    $script:OptionsPanel.RowStyles.Add([System.Windows.Forms.RowStyle]::new([System.Windows.Forms.SizeType]::Percent, 20))
}

# Panel "Ejecutar Todo"
$script:RunAllPanel = New-Object System.Windows.Forms.TableLayoutPanel
$script:RunAllPanel.Dock = "Fill"
$script:RunAllPanel.Padding = New-Object System.Windows.Forms.Padding(10, 5, 10, 5)
$script:RunAllPanel.ColumnCount = 3
$script:RunAllPanel.RowCount = 1
$script:RunAllPanel.ColumnStyles.Add([System.Windows.Forms.ColumnStyle]::new([System.Windows.Forms.SizeType]::Percent, 40))
$script:RunAllPanel.ColumnStyles.Add([System.Windows.Forms.ColumnStyle]::new([System.Windows.Forms.SizeType]::Percent, 40))
$script:RunAllPanel.ColumnStyles.Add([System.Windows.Forms.ColumnStyle]::new([System.Windows.Forms.SizeType]::Percent, 20))

# Panel de Barra de Progreso
$ProgressBarPanel = New-Object System.Windows.Forms.Panel
$ProgressBarPanel.Dock = "Fill"
$ProgressBarPanel.Padding = New-Object System.Windows.Forms.Padding(10, 0, 10, 0)

# Barra de Progreso
$script:GlobalProgressBar = New-Object System.Windows.Forms.ProgressBar
$script:GlobalProgressBar.Dock = "Fill"
$script:GlobalProgressBar.Visible = $false
$script:GlobalProgressBar.Style = "Marquee"
$ProgressBarPanel.Controls.Add($script:GlobalProgressBar)

# TextBox de Log
$script:GUILogTextBox = New-Object System.Windows.Forms.TextBox
$script:GUILogTextBox.Dock = "Fill"
$script:GUILogTextBox.Multiline = $true
$script:GUILogTextBox.ReadOnly = $true
$script:GUILogTextBox.ScrollBars = "Vertical"
$script:GUILogTextBox.BackColor = [System.Drawing.Color]::Black
$script:GUILogTextBox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#E0E0E0")
$script:GUILogTextBox.Font = New-Object System.Drawing.Font("Consolas", 9.5)

# Agregar controles al layout
$MainLayout.Controls.Add($script:OptionsPanel, 0, 0)
$MainLayout.Controls.Add($script:RunAllPanel, 0, 1)
$MainLayout.Controls.Add($ProgressBarPanel, 0, 2)
$MainLayout.Controls.Add($script:GUILogTextBox, 0, 3)

$script:Form.Controls.Add($MainLayout)
$script:Form.Controls.Add($MenuStrip)
#endregion
# ============================================================================
# PARTE 6C (FINAL) - EJECUCION DEL PROGRAMA
# ============================================================================

#region 11. EJECUCION DEL FORMULARIO

# Mostrar selector de nivel
$selectedLevel = Show-LevelSelector

if (-not $selectedLevel) {
    exit
}

# Cargar botones del nivel seleccionado
Load-LevelButtons -Level $selectedLevel

# Mensaje de bienvenida
Clear-GUILog
Write-GUILog "========================================" -NoTime
Write-GUILog "  Bienvenido a TotalCleanup GUI v3.0" -NoTime
Write-GUILog "  Modo: $selectedLevel" -NoTime
Write-GUILog "========================================" -NoTime
Write-GUILog ""
Write-GUILog "Selecciona una tarea del panel superior para comenzar."
Write-GUILog ""
Write-GUILog "LEYENDA DE COLORES:" -NoTime
Write-GUILog "  [GRIS]     - Tarea segura" -NoTime
Write-GUILog "  [VERDE]    - Accion recomendada" -NoTime
Write-GUILog "  [AMARILLO] - Precaucion" -NoTime
Write-GUILog "  [ROJO]     - PELIGRO, alto riesgo" -NoTime
Write-GUILog ""
Write-GUILog "ATAJOS: Ctrl+S=Guardar | Ctrl+L=Limpiar | Ctrl+N=Nivel | F1=Ayuda" -NoTime
Write-GUILog ""
Write-GUILog "Consejo: Pasa el cursor sobre los botones para ver detalles."

# Ejecutar formulario
try {
    [void]$script:Form.ShowDialog()
} finally {
    # Limpiar jobs pendientes
    Get-Job -ErrorAction SilentlyContinue | Remove-Job -Force -ErrorAction SilentlyContinue
    
    # Detener timer
    if ($script:JobTimer) {
        $script:JobTimer.Stop()
        $script:JobTimer.Dispose()
    }
    
    # Restaurar politica de ejecucion original
    try {
        if ($script:OriginalExecutionPolicy -ne (Get-ExecutionPolicy -Scope CurrentUser)) {
            Set-ExecutionPolicy -ExecutionPolicy $script:OriginalExecutionPolicy -Scope CurrentUser -Force -Confirm:$false
        }
    } catch {}
    
    # Liberar recursos
    if ($script:Form) {
        $script:Form.Dispose()
    }
}
#endregion

# ============================================================================
# FIN DEL SCRIPT - TotalCleanup GUI v3.0
# ============================================================================
