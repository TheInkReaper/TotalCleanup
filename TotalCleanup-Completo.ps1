# -*- coding: utf-8 -*-
<#
.SYNOPSIS
    Herramienta Profesional de Mantenimiento de Windows (Consola v4.7).
.DESCRIPTION
    Versión final con correcciones de formato y colores en el menú y la bienvenida.
.AUTHOR
    TheInkReaper
#>

#region 1. CONFIGURACIÓN INICIAL Y PERMISOS
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Elevando permisos..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -File `"$PSCommandPath`""
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
function Write-ConsoleLog { Param([string]$Message, [string]$ColorName = "Green", [switch]$NoTime) $output = if ($NoTime) { $Message } else { "$((Get-Date -Format 'HH:mm:ss')) - $Message" }; Write-Host $output -ForegroundColor $ColorName; if (-not $NoTime) { [void]$scriptLogContent.AppendLine($output) } }
function Show-WelcomeScreen {
    Clear-Host
    Write-Host "====================================================================" -ForegroundColor DarkYellow
    Write-Host "       BIENVENIDO A LA HERRAMIENTA DE MANTENIMIENTO COMPLETO" -ForegroundColor Yellow
    Write-Host "====================================================================" -ForegroundColor DarkYellow
    Write-Host "INFORMACIÓN IMPORTANTE Y ADVERTENCIAS:" -ForegroundColor Red
    Write-Host "--------------------------------------------------------------------" -ForegroundColor DarkRed
    
    # CORRECCIÓN: Se escriben las líneas individualmente para asignarles color
    Write-Host "1.  PERMISOS DE ADMINISTRADOR: Asegúrese de ejecutar este script como administrador." -ForegroundColor White
    Write-Host "2.  PUNTO DE RESTAURACIÓN: Se recomienda crearlo antes de realizar cambios significativos." -ForegroundColor White
    Write-Host "3.  REINICIOS: Algunas tareas (como CHKDSK) requieren reiniciar el equipo para completarse." -ForegroundColor White
    Write-Host "4.  RIESGOS DE LAS FUNCIONES: Proceda con precaución." -ForegroundColor White
    Write-Host "    - Amarillo:" -ForegroundColor Yellow -NoNewLine; Write-Host " La tarea requiere un reinicio o interacción manual." -ForegroundColor White
    Write-Host "    - Rojo:    " -ForegroundColor Red -NoNewLine; Write-Host " La tarea es de ALTO RIESGO y puede causar inestabilidad." -ForegroundColor White

    Write-Host "--------------------------------------------------------------------" -ForegroundColor DarkRed
    Write-Host "`nPresione cualquier tecla para continuar..." -ForegroundColor Yellow
    $null = Read-Host
}
#endregion

#region 3. DEFINICIÓN DE TAREAS
function Limpiar-CacheDNS { Write-ConsoleLog "Limpiando Caché DNS..."; try { ipconfig /flushdns | Out-Null; Write-ConsoleLog "OK." -Color Green } catch { Write-ConsoleLog "Error." -Color Red } }
function Limpiar-ArchivosTemporales { Write-ConsoleLog "Limpiando Archivos Temporales..."; try { Remove-Item "$env:TEMP\*" -Recurse -Force -EA 0; Remove-Item (Join-Path $env:SystemRoot "Temp\*") -Recurse -Force -EA 0; Write-ConsoleLog "OK." -Color Green } catch { Write-ConsoleLog "Error." -Color Red } }
function Vaciar-Papelera { Write-ConsoleLog "Vaciando Papelera..."; try { Clear-RecycleBin -Force -EA 0; Write-ConsoleLog "OK." -Color Green } catch { Write-ConsoleLog "Error." -Color Red } }
function Limpiar-CacheWindowsUpdate { Write-ConsoleLog "Limpiando Caché de WU..."; try { Stop-Service wuauserv -Force -EA Stop; Remove-Item (Join-Path $env:SystemRoot "SoftwareDistribution\Download\*") -Recurse -Force -EA 0; Start-Service wuauserv -EA Stop; Write-ConsoleLog "OK." -Color Green } catch { Write-ConsoleLog "Error." -Color Red } }
function Ejecutar-DISM { Write-ConsoleLog "Ejecutando DISM..."; try { Write-Host "Paso 1/3: CheckHealth..."; $p = Start-Process DISM.exe -ArgumentList "/Online /Cleanup-Image /CheckHealth" -Wait -NoNewWindow -PassThru; if ($p.ExitCode -ne 0) { Write-Host "Problema detectado" -ForegroundColor Yellow }; Write-Host "Paso 2/3: ScanHealth..."; $p = Start-Process DISM.exe -ArgumentList "/Online /Cleanup-Image /ScanHealth" -Wait -NoNewWindow -PassThru; if ($p.ExitCode -ne 0) { Write-Host "Problema detectado" -ForegroundColor Yellow }; Write-Host "Paso 3/3: RestoreHealth..."; $p = Start-Process DISM.exe -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -Wait -NoNewWindow -PassThru; if ($p.ExitCode -ne 0) { Write-Host "Error" -ForegroundColor Red } else { Write-ConsoleLog "OK." -Color Green } } catch { Write-ConsoleLog "Error." -Color Red } }
function Ejecutar-SFC { Write-ConsoleLog "Ejecutando SFC..."; try { sfc /scannow | Out-Null; if ($LASTEXITCODE -eq 0) {Write-ConsoleLog "OK. No se encontraron violaciones de integridad." -Color Green} elseif ($LASTEXITCODE -eq 3010) {Write-ConsoleLog "OK. Archivos reparados. REINICIAR." -Color Yellow} else {Write-ConsoleLog "Error. No se pudo reparar." -Color Red}} catch { Write-ConsoleLog "Error." -Color Red }}
function Ejecutar-CHKDSK { Write-ConsoleLog "Programar CHKDSK..."; $drives=Get-PSDrive -PSProvider FileSystem|?{$_.Free -ne $null}; $drives|%{"- $($_.Name)"}|Write-Host; $drive=Read-Host "Elige unidad"; if($drive -and ($drives.Name -contains $drive.ToUpper())){chkdsk "$($drive.ToUpper()):" /r; Write-ConsoleLog "CHKDSK para $drive programado. REINICIAR." -Color Yellow}else{Write-ConsoleLog "Cancelado."}}
function Ver-SaludDiscos { Write-ConsoleLog "Estado S.M.A.R.T. de los discos..."; Get-PhysicalDisk | ft FriendlyName, MediaType, HealthStatus -A; Write-ConsoleLog "Completado." }
function Verificar-ReinicioPendiente { Write-ConsoleLog "Verificando reinicios..."; $needed=$false; $paths="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired","HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"; $paths|% {if(Test-Path $_){$needed=$true;Write-ConsoleLog "Reinicio pendiente detectado." -Color Yellow}}; if(!$needed){Write-ConsoleLog "No se necesita reiniciar." -Color Green}}
function Limpiar-VSS { Write-ConsoleLog "Limpieza de Puntos de Restauración..."; if('s' -eq (Read-Host "ADVERTENCIA: ¿Eliminar TODOS los puntos de restauración? (s/n)")) { try { Write-ConsoleLog "Eliminando..."; vssadmin delete shadows /all /quiet; Write-ConsoleLog "OK." -Color Green } catch {Write-ConsoleLog "Error." -Color Red} } else { Write-ConsoleLog "Cancelado." }}
function Gestionar-PlanesEnergia { Write-ConsoleLog "Planes de Energía..."; powercfg /list; $guid=Read-Host "Pega el GUID a activar"; if($guid){powercfg /setactive $guid; Write-ConsoleLog "OK." -Color Green}else{Write-ConsoleLog "Cancelado."}}
function Crear-PuntoRestauracion { Write-ConsoleLog "Creando Punto de Restauración..."; try { Checkpoint-Computer -Desc "TotalCleanupConsole_$(Get-Date -F 'yyyyMMdd_HHmmss')"; Write-ConsoleLog "OK." -Color Green } catch { Write-ConsoleLog "Error." -Color Red }}
function Generar-InformeSesion { Write-ConsoleLog "Generando informe de sesión..."; try { $path=Join-Path $PSScriptRoot "Session_Report_Console_$((Get-Date)-F 'yyyyMMdd_HHmmss').log"; Add-Content -Path $path -Value $scriptLogContent.ToString(); Write-ConsoleLog "Informe guardado." -Color Green} catch {Write-ConsoleLog "Error." -Color Red}}
#endregion

#region 4. MENÚ Y BUCLE PRINCIPAL
function Show-MaintenanceMenu { 
    Clear-Host
    Write-Host "--- Herramienta de Mantenimiento v4.7 ---" -ForegroundColor Yellow
    Write-Host "Selecciona una opción:" -ForegroundColor Cyan
    Write-Host "`n--- LIMPIEZA ---" -ForegroundColor Green
    "1. Limpiar Caché DNS", "2. Limpiar Archivos Temporales", "3. Vaciar Papelera", "4. Limpiar Caché de Windows Update" | ForEach-Object {Write-Host "  $_"}
    Write-Host "`n--- REPARACIÓN Y DIAGNÓSTICO ---" -ForegroundColor Green
    "5. Ejecutar Comandos DISM", "6. Ejecutar SFC /scannow", "7. Programar CHKDSK", "8. Ver Salud Discos (S.M.A.R.T.)", "9. Verificar Reinicio Pendiente" | ForEach-Object {Write-Host "  $_"}
    Write-Host "`n--- AVANZADO / UTILIDADES ---" -ForegroundColor Yellow
    "10. Gestionar Planes de Energía" | ForEach-Object {Write-Host "  $_"}
    # CORRECCIÓN: Se añade el espacio inicial y el color correcto
    Write-Host "  11. Limpiar Puntos de Restauración (VSS)" -ForegroundColor Red
    "12. Crear Punto de Restauración", "13. Generar Informe de Sesión" | ForEach-Object {Write-Host "  $_" -ForegroundColor Yellow}
    Write-Host "`n0. Salir" -ForegroundColor Red
}
Show-WelcomeScreen
try { do { Show-MaintenanceMenu; $choice = Read-Host "`nIngresa tu opción"; $scriptLogContent.Clear(); switch ($choice) { "1" { Limpiar-CacheDNS } "2" { Limpiar-ArchivosTemporales } "3" { Vaciar-Papelera } "4" { Limpiar-CacheWindowsUpdate } "5" { Ejecutar-DISM } "6" { Ejecutar-SFC } "7" { Ejecutar-CHKDSK } "8" { Ver-SaludDiscos } "9" { Verificar-ReinicioPendiente } "10" { Gestionar-PlanesEnergia } "11" { Limpiar-VSS } "12" { Crear-PuntoRestauracion } "13" { Generar-InformeSesion } "0" { break } default { Write-ConsoleLog "Opción no válida." -Color Red } }; if ($choice -ne "0") { Write-Host "`nPresiona cualquier tecla para volver al menú..."; $null = Read-Host } } while ($choice -ne "0") } finally { if ($originalExecutionPolicy -ne (Get-ExecutionPolicy -Scope CurrentUser)) { Set-ExecutionPolicy -ExecutionPolicy $originalExecutionPolicy -Scope CurrentUser -Force -Confirm:$false }; Write-ConsoleLog "Herramienta finalizada." -Color Green }
#endregion