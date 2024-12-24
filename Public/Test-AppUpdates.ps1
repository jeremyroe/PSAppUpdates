function Test-AppUpdates {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$Applications,
        
        [Parameter()]
        [switch]$All,

        [Parameter()]
        [string]$LogPath,

        [Parameter()]
        [switch]$Silent
    )
    
    try {
        Write-Verbose "TESTING MODE: No changes will be made to applications"
        
        # Install prerequisites if needed (this is required for testing)
        $prereqMessage = "Installing required prerequisites (winget and osquery)"
        if ($Silent -or $PSCmdlet.ShouldContinue($prereqMessage, "Install Prerequisites")) {
            Write-AppLog "Checking prerequisites..." -LogPath $LogPath
            Install-Prerequisites
        }
        else {
            throw "Prerequisites check cancelled by user"
        }

        # Get applications to check
        if ($All) {
            $Applications = (Get-AppConfig).PSObject.Properties.Name
        }
        
        Write-Verbose "`nApplication Update Check:"
        $results = @()
        foreach ($app in $Applications) {
            Write-Verbose "  Checking $app..."
            $config = Get-AppConfig -Application $app
            if (-not $config) {
                Write-Warning "Application '$app' not supported"
                continue
            }
            
            # Check current state
            Write-Verbose "  - Checking $($config.displayName) (ID: $($config.wingetId))"
            
            # Use list instead of upgrade to avoid triggering installation
            $appInfo = winget list --id $config.wingetId --accept-source-agreements | Select-String $config.wingetId
            if (-not $appInfo) {
                $action = "Would install (not currently installed)"
                $updateAvailable = $true
            } else {
                # Check if update is available without triggering it
                $updateCheck = winget list --upgrade --id $config.wingetId | Select-String $config.wingetId
                $updateAvailable = ($null -ne $updateCheck)
                $action = if ($updateAvailable) { 
                    "Would update to latest version"
                } else {
                    "No update required"
                }
            }

            $processesRunning = $config.processNames | Where-Object { Get-Process -Name $_ -ErrorAction SilentlyContinue }
            
            $results += [PSCustomObject]@{
                Name = $app
                DisplayName = $config.displayName
                UpdateAvailable = $updateAvailable
                ProcessesRunning = if ($processesRunning) { $true } else { $false }
                WouldRequireClose = if ($processesRunning) { $true } else { $false }
                Action = $action
            }
        }
        
        # Summary report
        Write-Verbose "`nTest Results Summary:"
        Write-Verbose "  Total applications checked: $($results.Count)"
        Write-Verbose "  Updates available: $($results.Where({ $_.UpdateAvailable }).Count)"
        Write-Verbose "  Applications running: $($results.Where({ $_.ProcessesRunning }).Count)"
        
        return $results
    }
    catch {
        Write-ErrorHandler $_ "Failed in Test-AppUpdates" -LogPath $LogPath -ThrowError
    }
} 