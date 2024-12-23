function Get-AppConfig {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Application
    )
    
    $configPath = Join-Path $PSScriptRoot "..\Config\Applications.json"
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    
    if ($Application) {
        return $config.$Application
    }
    
    return $config
} 