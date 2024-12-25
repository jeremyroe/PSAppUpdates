function Test-Installation {
    [CmdletBinding()]
    param()
    
    Write-Host "Testing PSAppUpdates installation..."
    
    # Check module is loaded
    $module = Get-Module PSAppUpdates
    Write-Host "Module version: $($module.Version)"
    
    # Check Applications.json exists and content
    $configPath = Join-Path $module.ModuleBase "Config\Applications.json"
    if (Test-Path $configPath) {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        Write-Host "`nSupported Applications:"
        $config.PSObject.Properties | ForEach-Object {
            Write-Host "- $($_.Name): $($_.Value.displayName)"
        }
    }
    else {
        Write-Warning "Applications.json not found at: $configPath"
    }
}

Test-Installation 