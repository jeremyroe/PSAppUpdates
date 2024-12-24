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
            
            # Check if app is installed
            $appInfo = winget list --id $config.wingetId --accept-source-agreements | Select-String $config.wingetId
            if (-not $appInfo) {
                Write-Verbose "  - $($config.displayName) is not installed - skipping"
                continue  # Skip this app since we only update existing installations
            }

            # Check if update is available without triggering it
            Write-Verbose "  - Checking $($config.displayName) for updates..."
            $outdated = choco outdated $config.packageId -r
            $updateAvailable = $outdated -match $config.packageId
            $action = if ($updateAvailable) { 
                "Would update to latest version"
            } else {
                "No update required"
            }

            # Check for running processes more thoroughly
            $processesRunning = @()
            foreach ($processName in $config.processNames) {
                # Strip .exe if present for consistency
                $baseName = $processName -replace '\.exe$', ''
                $running = Get-Process -Name $baseName -ErrorAction SilentlyContinue
                if ($running) {
                    Write-Verbose "  - Found running process: $baseName"
                    $processesRunning += $running
                }
            }
            
            $results += [PSCustomObject]@{
                Name = $app
                DisplayName = $config.displayName
                UpdateAvailable = $updateAvailable
                ProcessesRunning = $processesRunning.Count -gt 0
                RunningProcesses = $processesRunning | Select-Object -ExpandProperty ProcessName -Unique
                WouldRequireClose = $processesRunning.Count -gt 0
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