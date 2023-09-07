<#
  .SYNOPSIS
  Sets the power plan for the local machine
  
  .DESCRIPTION
  Sets the active plan 
  
  get-help Set-Powerplan.ps1 -Full

  .PARAMETER Plan
  Name of the power plan to set

  .EXAMPLE
  Set-Powerplan.ps1 -Plan "Power saver"
#>

param([string]$Plan)

$powerConstants = @{}
PowerCfg.exe -ALIASES | Where-Object { $_ -match 'SCHEME_' } | ForEach-Object {
    $guid, $alias = ($_ -split '\s+', 2).Trim()
    $powerConstants[$guid] = $alias
}

# get a list of power schemes
$powerSchemes = PowerCfg.exe -LIST | Where-Object { $_ -match '^Power Scheme' } | ForEach-Object {
    $guid = $_.SubString(19, 36)
    $name = $_.SubString(58)
    $active = ($_.SubString($_.length - 1, 1) -eq '*')
    if ($active) {
        $name = $name.SubString(0, $name.length - 3)
    }
    else {
        $name = $name.SubString(0, $name.length - 1)
    }
    [PsCustomObject]@{
        IsActive = $active
        Name     = $name
        Guid     = $guid
    } 
}



$desiredScheme = $powerSchemes | Where-Object { $_.Name -eq $Plan -and $_.IsActive -eq $false }

if ($null -ne $desiredScheme) {
    Powercfg.exe -SETACTIVE $desiredScheme.Guid
    # test if the setting has changed
    $currentPowerGuid = (Powercfg.exe -GETACTIVESCHEME) -replace '.*GUID:\s*([-a-f0-9]+).*', '$1'
    if ($currentPowerGuid -eq $desiredScheme.Guid) {
        Write-Host "Power plan changed to $($plan)"
    }
}