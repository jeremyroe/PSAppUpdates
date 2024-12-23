function Update-AppGeneric {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Config,
        
        [Parameter()]
        [switch]$Force,
        
        [Parameter()]
        [switch]$ForceClose,
        
        [Parameter()]
        [int]$MaxRetries = 3,

        [Parameter()]
        [string]$LogPath
    )
    
    Write-AppLog -Message "Starting update for $($Config.displayName)" -LogPath $LogPath
    
    # Check if app is running
    if ($ForceClose) {
        foreach ($process in $Config.processNames) {
            try {
                $runningProcesses = Get-Process -Name $process -ErrorAction SilentlyContinue
                if ($runningProcesses) {
                    Write-AppLog -Message "Closing $process" -Level Warning -LogPath $LogPath
                    $runningProcesses | Stop-Process -Force
                }
            }
            catch {
                Write-AppLog -Message "Failed to close $process : $_" -Level Error -LogPath $LogPath
            }
        }
    }
    
    # Handle legacy versions if defined
    if ($Config.legacyAction -eq "uninstall") {
        Write-AppLog -Message "Checking for legacy versions" -LogPath $LogPath
        # Implementation needed for legacy version handling
    }
    
    # Update using winget with retry logic
    $attempt = 1
    $success = $false
    
    do {
        try {
            Write-AppLog -Message "Update attempt $attempt of $MaxRetries" -LogPath $LogPath
            
            $command = "winget upgrade --id $($Config.wingetId)"
            if ($Force) {
                $command += " --force"
            }
            
            $result = Invoke-Expression $command
            
            if ($LASTEXITCODE -eq 0) {
                $success = $true
                Write-AppLog -Message "Successfully updated $($Config.displayName)" -LogPath $LogPath
                break
            }
            else {
                Write-AppLog -Message "Attempt $attempt failed with exit code $LASTEXITCODE" -Level Warning -LogPath $LogPath
            }
        }
        catch {
            Write-AppLog -Message "Error during update attempt $attempt : $_" -Level Error -LogPath $LogPath
        }
        
        $attempt++
        if ($attempt -le $MaxRetries) {
            Start-Sleep -Seconds 5
        }
    } while ($attempt -le $MaxRetries)
    
    if (-not $success) {
        Write-AppLog -Message "Failed to update $($Config.displayName) after $MaxRetries attempts" -Level Error -LogPath $LogPath
        throw "Failed to update $($Config.displayName)"
    }
} 