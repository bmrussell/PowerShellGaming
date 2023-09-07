<#
  .SYNOPSIS
  Get the power plans configured for the local machine
  
  .DESCRIPTION
  Returns the active  plan or a list of al plans
  
  get-help Get-Powerplan.ps1 -Full

  .PARAMETER All
  Return all plans, including the active status and identifying GUID

  .EXAMPLE
  Get-Powerplan.ps1 

  .EXAMPLE
  Get-Powerplan.ps1 -All

#>

param([switch]$All)

$powerConstants = @{}
PowerCfg.exe -ALIASES | Where-Object { $_ -match 'SCHEME_' } | ForEach-Object {
    $guid, $alias = ($_ -split '\s+', 2).Trim()
    $powerConstants[$guid] = $alias
}

# get a list of power schemes
$powerSchemes = PowerCfg.exe -LIST | Where-Object { $_ -match '^Power Scheme' } | ForEach-Object {
    $guid = $_.SubString(19, 36)
    $name = $_.SubString(58)
    $active = ($_.SubString($_.length-1, 1) -eq '*')
    if ($active) {
        $name = $name.SubString(0, $name.length-3)
    } else {
        $name = $name.SubString(0, $name.length-1)
    }
    [PsCustomObject]@{
		IsActive = $active
        Name     = $name
        Guid     = $guid
    } 
}

if ($All.IsPresent) {
    $powerSchemes
}
else {
    $activeScheme = $powerSchemes | Where-Object { $_.IsActive -eq $True }
    $activeScheme.Name
}