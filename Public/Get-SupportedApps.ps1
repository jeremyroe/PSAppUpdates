function Get-SupportedApps {
    [CmdletBinding()]
    param()
    
    $config = Get-AppConfig
    $apps = @()
    
    foreach ($app in $config.PSObject.Properties) {
        $apps += [PSCustomObject]@{
            Name = $app.Name
            DisplayName = $app.Value.displayName
            WingetId = $app.Value.wingetId
        }
    }
    
    return $apps
} 