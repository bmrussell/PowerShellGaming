
<#
  .SYNOPSIS
  Grants current user rights to start & stop certain services
  
  .DESCRIPTION
  Grants current user rights to start & stop certain services, The hard coded list may be overriden
  by the environment variable $Env:USER_STOPPABLE_SERVICES which is a pipe-seperated string of
  service names.

  Depends on PowerShell module Carbon: https://www.powershellgallery.com/packages/Carbon/2.15.1
    Install-Module Carbon
    Import-Module Carbon
  
  Get-Help Grant-ServiceStopStart.ps1 -Full

  .PARAMETER WhatIf
  Just list the commands that would be executed

  .PARAMETER List
  List the services that will be set if the command is run. This is only running services from the hard coded list. 

  .EXAMPLE
  Grant-ServiceStopStart.ps1 -WhatIf

  .EXAMPLE
  Grant-ServiceStopStart.ps1 -List

  .EXAMPLE
  Grant-ServiceStopStart.ps1
#>
param([switch]$WhatIf, [switch]$List)

$servicenames = 'AdobeARMservice|AdobeUpdateService'

if ($null -ne $Env:USER_STOPPABLE_SERVICES) {
    $servicenames = $Env:USER_STOPPABLE_SERVICES
}

$services = Get-Service -Erroraction SilentlyContinue | Where-Object { $_.Name -match $servicenames -and $_.Status -eq 'Running'}

if ($List.IsPresent) {
    $services | Select-Object Name
} else {
    if ($WhatIf.IsPresent) {
        $services | ForEach-Object { Write-Host "Grant-CServiceControlPermission -ServiceName $($_.Name) -Identity `"$($Env:COMPUTERNAME)\$($Env:USERNAME)`"" }
        
    } else {
        $services | ForEach-Object { Grant-CServiceControlPermission -Erroraction SilentlyContinue -ServiceName $_.Name -Identity "$($Env:COMPUTERNAME)\$($Env:USERNAME)" }
    }
}