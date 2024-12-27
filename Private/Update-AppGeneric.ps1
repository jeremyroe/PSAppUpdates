function Update-AppGeneric {
    [CmdletBinding(SupportsShouldProcess)]
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
    
    # Handle process closing if needed
    if ($ForceClose) {
        foreach ($process in $Config.processNames) {
            try {
                $runningProcesses = Get-Process -Name $process -ErrorAction SilentlyContinue
                if ($runningProcesses) {
                    Write-AppLog -Message "Closing $process" -Level Warning -LogPath $LogPath
                    $runningProcesses | Stop-Process -Force
                    Start-Sleep -Seconds 2  # Give processes time to close
                }
            }
            catch {
                Write-AppLog -Message "Failed to close $process : $_" -Level Error -LogPath $LogPath
            }
        }
    }

    # Perform update based on update type
    $attempt = 1
    $success = $false
    
    do {
        try {
            Write-AppLog -Message "Update attempt $attempt of $MaxRetries" -LogPath $LogPath
            
            switch ($Config.updateType) {
                'adobe' {
                    # Get version info
                    $versionInfo = Get-AdobeVersion -LogPath $LogPath
                    if (-not $versionInfo.NeedsUpdate) {
                        Write-AppLog "Adobe Acrobat is up to date" -LogPath $LogPath
                        return $true
                    }

                    if ($PSCmdlet.ShouldProcess($Config.displayName, "Update from $($versionInfo.Installed) to $($versionInfo.Latest)")) {
                        # Construct update URL using Adobe's pattern
                        $updateUrl = "https://ardownload2.adobe.com/pub/adobe/acrobat/win/AcrobatDC/$($versionInfo.Latest)/AcroRdrDCUpd$($versionInfo.Latest).msp"
                        $updateFile = Join-Path $env:TEMP "AcrobatUpdate_$($versionInfo.Latest).msp"
                        
                        # Download update package
                        Write-AppLog "Downloading Adobe update package" -LogPath $LogPath
                        Invoke-WebRequest -Uri $updateUrl -OutFile $updateFile
                        
                        if (-not (Test-Path $updateFile)) {
                            throw "Update package download failed"
                        }
                        
                        # Install update
                        $arguments = @(
                            "/p `"$updateFile`""  # Patch
                            "/qn"                 # Silent
                            "/norestart"          # Prevent automatic restart
                            "/l*v `"$env:TEMP\AdobeUpdate_$($versionInfo.Latest).log`""  # Logging
                        )
                        
                        $result = Start-Process -FilePath "msiexec.exe" -ArgumentList ($arguments -join ' ') -Wait -PassThru
                        
                        # Cleanup
                        Remove-Item $updateFile -Force -ErrorAction SilentlyContinue
                        
                        if ($result.ExitCode -in @(0, 3010)) {
                            $success = $true
                            Write-AppLog "Adobe update installed successfully" -LogPath $LogPath
                            break
                        }
                        throw "Update failed with exit code: $($result.ExitCode)"
                    }
                }
                
                default {
                    # Standard Winget update
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
                    throw "Update failed with exit code: $LASTEXITCODE"
                }
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
    
    return $success
} 