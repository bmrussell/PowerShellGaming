
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
  Process name of the game to wait for.

  .PARAMETER Plan
  Power plan name to set while the game is running.

  .PARAMETER Wait
  Numebr of seconds after launching the game before waiting for the game to finish. Works around launchers not being the real game.

  .PARAMETER Width
  New screen resolution width to set

  .PARAMETER Height
  New screen resolution height to set

  .PARAMETER Trace
  When given, print actions to console before executing

  .LINK
  Source Repository: https://github.com/bmrussell/PowerShellGaming

  .EXAMPLE
  Play-Game.ps1 -Launch "D:\Games\GOG\Cyberpunk 2077\bin\x64\Cyberpunk2077.exe" -Name "Cyberpunk2077" -Plan "GameTurbo (High Performance)" -Wait 30 -Width 3440 -Height 1440


#>

param([string]$Launch, [string]$Name, [string]$Plan, [int]$Wait, [int]$Width, [int]$Height, [switch]$Trace)

if ($Plan -ne "") {    
    $currentPlan = Get-Powerplan.ps1
    if ($Trace.IsPresent) { Write-Host "Got current power plan plan: $($currentPlan)"}
}

if ($Plan -ne "") {
    if ($Trace.IsPresent) { Write-Host "Setting power plan: $($Plan)"}
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

if ($Width -ne "" -and $Height -ne "") {    
    Set-DisplayResolution -Width $Width -Height $Height
    if ($Trace.IsPresent) { Write-Host "Setting screen res: $($Width)x$($Height)"}
}

$proc = Start-Process -FilePath $Launch -PassThru
# Waiting here won't work because game launchers OF COURSE
if ($Wait -ne 0) {
    if ($Trace.IsPresent) { Write-Host "Waiting: $($Wait)s"}
    Start-Sleep -Seconds $Wait
}

if ($Name -ne "") {
    if ($Trace.IsPresent) { Write-Host "Waiting for: $($Name) to quit"}
    Wait-Process -Name $Name
} else {
    $proc.WaitForExit()
}

# Workaround for packaged exes that launch another like aliens dark descent
# causing Access is denied error
while ($null -ne (Get-Process -Name $Name)) {
    Start-Sleep -Seconds $Wait
    Write-Host -NoNewline "."
}
Write-Host ""

if ($Width -ne "" -and $Height -ne "") {
    if ($Trace.IsPresent) { Write-Host "Setting screen res: $($currentWidth)x$($currentHeight)"}
    Set-DisplayResolution -Width $currentWidth -Height $currentHeight
}

if ($Plan -ne "") {
    if ($Trace.IsPresent) { Write-Host "Setting power plan: $($currentPlan)"}
    Set-Powerplan.ps1 -Plan $currentPlan
}
