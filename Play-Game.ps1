
<#
  .SYNOPSIS
  Temporarily optimise Windows to launch a game and return to previous settings when done.
  
  .DESCRIPTION
  1. Sets power plan
  2. Changes screen resolution (I'm looking at you Starfield
  3. Waits for game to finish
  4. Returns settings to previous values
  
  get-help Play-Game.ps1 -Full

  .PARAMETER Launch
  Path to shortcut or EXE file.
  
  .PARAMETER Name
  Process name of the game to wait for. Can include wildcards.

  .PARAMETER Plan
  Power plan name to set while the game is running.

  .PARAMETER Wait
  Numebr of seconds after launching the game before waiting for the game to finish. Works around launchers not being the real game.

  .PARAMETER Width
  New screen resolution width to set

  .PARAMETER Height
  New screen resolution height to set

  .PARAMETER HDR
  When given, toggle HDR on for the game and off again at finish

  .PARAMETER Trace
  When given, print actions to console before executing

  .PARAMETER StopServices
  Stop non-essential services and restart on quit. List of services should be a pipe seperated string in $Env:USER_STOPPABLE_SERVICES. 

  .NOTES
  The user must have Start/Stop rights on the services to be controlled. Use Carbon directly or Grant-ServiceStopStart.ps1 to grant rights.

  .LINK
  Source Repository: https://github.com/bmrussell/PowerShellGaming

  .EXAMPLE
  Play-Game.ps1 -Launch '"C:\Users\brian\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Games\Cyberpunk 2077.lnk"' -Plan "'GameTurbo (High Performance)'" -Name "Cyberpunk2077" -Wait 15 -HDR
  
  .EXAMPLE
  Play-Game.ps1 -Launch "'J:\SteamLibrary\steamapps\common\The Ascent\TheAscent.exe'" -Plan "'GameTurbo (High Performance)'" -Name 'TheAscent*' -Wait 5
#>

param([string]$Launch, [string]$Name, [string]$Plan, [int]$Wait, [int]$Width, [int]$Height, [switch]$Trace, [switch]$HDR, [switch]$StopServices)

if ($Plan -ne "") {    
    $currentPlan = Get-Powerplan.ps1
    if ($Trace.IsPresent) { Write-Host "Got current power plan plan: $($currentPlan)" }
}

if ($Plan -ne "") {
    if ($Trace.IsPresent) { Write-Host "Setting power plan: $($Plan)" }
    Set-Powerplan.ps1 -Plan $Plan
}

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class PInvoke {
    [DllImport("user32.dll")] public static extern IntPtr GetDC(IntPtr hwnd);
    [DllImport("gdi32.dll")] public static extern int GetDeviceCaps(IntPtr hdc, int nIndex);
}
"@
$hdc = [PInvoke]::GetDC([IntPtr]::Zero)
$currentWidth = [PInvoke]::GetDeviceCaps($hdc, 118)
$currentHeight = [PInvoke]::GetDeviceCaps($hdc, 117)
if ($Trace.IsPresent) { Write-Host "Original screen res: $($currentWidth)x$($currentHeight)" }

if ($Width -ne 0 -and $Height -ne 0) {    
    Set-DisplayResolution -Width $Width -Height $Height
    if ($Trace.IsPresent) { Write-Host "Setting screen res: $($Width)x$($Height)" }
}

if ($HDR.IsPresent) {
    if ($Trace.IsPresent) { Write-Host "HDR on"}
    Start-Process "hdr_switch_tray" hdr
}

if ($null -ne $Env:USER_STOPPABLE_SERVICES -and $StopServices.IsPresent) {    
    $services = Get-Service -Erroraction SilentlyContinue | Where-Object { $_.Name -match $Env:USER_STOPPABLE_SERVICES -and $_.Status -eq 'Running'}
    if ($Trace.IsPresent) { Write-Host "Stopping $($services.length) services..." }
    $services | ForEach-Object { Write-Host "Stopping $($_.Name)..."; Stop-Service -Erroraction SilentlyContinue -Name $_.Name }
}


Start-Process -FilePath $Launch

# Wait adds contingency for a launcher to launch the actual game
if ($Wait -ne 0) {
    if ($Trace.IsPresent) { Write-Host "Waiting: $($Wait)s" }
    Start-Sleep -Seconds $Wait
}

# Can't use $proc.WaitForExit() so workaround for packaged exes that launch another like aliens dark descent
# is just to poll
if ("" -ne $Name) {
    while ($null -ne (Get-Process -Erroraction SilentlyContinue -Name $Name)) {
        Start-Sleep -Seconds $Wait
        Write-Host -NoNewline "."
    }
    Write-Host ""
}

if ($Width -ne 0 -and $Height -ne 0) {
    if ($Trace.IsPresent) { Write-Host "Setting screen res: $($currentWidth)x$($currentHeight)" }
    Set-DisplayResolution -Width $currentWidth -Height $currentHeight
}

if ($Trace.IsPresent) {    
    $restoredWidth = [PInvoke]::GetDeviceCaps($hdc, 118)
    $restoredHeight = [PInvoke]::GetDeviceCaps($hdc, 117)
    Write-Host "Restored screen res: $($restoredWidth)x$($restoredHeight)"
}

if ($HDR.IsPresent) {
    if ($Trace.IsPresent) { Write-Host "HDR off"}
    & hdr_switch_tray hdr
}

if ($Plan -ne "") {
    if ($Trace.IsPresent) { Write-Host "Setting power plan: $($currentPlan)" }
    Set-Powerplan.ps1 -Plan $currentPlan
}

if ($null -ne $services -and $StopServices.IsPresent) {
    if ($Trace.IsPresent) { Write-Host "Starting $($services.length) services..." }
    $services | ForEach-Object { Write-Host "Starting $($_.Name)..."; Start-Service -Erroraction SilentlyContinue -Name $_.Name }
}

if ($Trace.IsPresent) {
    Write-Host "Done"
    Read-Host "[ENTER]"
}