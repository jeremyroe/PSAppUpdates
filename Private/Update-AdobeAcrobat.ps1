function Update-AdobeAcrobat {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$CurrentVersion,
        
        [Parameter(Mandatory)]
        [string]$TargetVersion,

        [Parameter()]
        [string]$LogPath,

        [Parameter()]
        [switch]$Force
    )
    
    try {
        Write-AppLog "Preparing Adobe Acrobat DC update..." -LogPath $LogPath
        
        # Construct update URL using Adobe's pattern
        $updateUrl = "https://ardownload2.adobe.com/pub/adobe/acrobat/win/AcrobatDC/$TargetVersion/AcroRdrDCUpd$TargetVersion.msp"
        $updateFile = Join-Path $env:TEMP "AcrobatUpdate_$TargetVersion.msp"
        
        # Download update package
        Write-AppLog "Downloading update package from $updateUrl" -LogPath $LogPath
        try {
            Invoke-WebRequest -Uri $updateUrl -OutFile $updateFile
            if (-not (Test-Path $updateFile)) {
                throw "Update package not found after download"
            }
        }
        catch {
            throw "Failed to download update package: $_"
        }
        
        # Verify running processes
        $processes = Get-Process -Name "Acrobat", "AcroRd32" -ErrorAction SilentlyContinue
        if ($processes -and -not $Force) {
            Write-AppLog "Adobe Acrobat processes found running. Use -Force to close automatically." -Level Warning -LogPath $LogPath
            return $false
        }
        elseif ($processes -and $Force) {
            Write-AppLog "Closing running Adobe Acrobat processes..." -LogPath $LogPath
            $processes | Stop-Process -Force
            Start-Sleep -Seconds 2
        }
        
        # Install update if confirmed
        if ($PSCmdlet.ShouldProcess("Adobe Acrobat DC", "Update from $CurrentVersion to $TargetVersion")) {
            Write-AppLog "Installing update..." -LogPath $LogPath
            
            $arguments = @(
                "/p `"$updateFile`""  # Patch
                "/qn"                 # Silent
                "/norestart"          # Prevent automatic restart
                "/l*v `"$env:TEMP\AdobeUpdate_$TargetVersion.log`""  # Verbose logging
            )
            
            $result = Start-Process -FilePath "msiexec.exe" -ArgumentList ($arguments -join ' ') -Wait -PassThru
            
            switch ($result.ExitCode) {
                0 { 
                    Write-AppLog "Update installed successfully" -LogPath $LogPath
                    return $true 
                }
                3010 { 
                    Write-AppLog "Update installed successfully - restart required" -Level Warning -LogPath $LogPath
                    return $true 
                }
                default {
                    throw "Update installation failed with exit code: $($result.ExitCode)"
                }
            }
        }
        
        return $false
    }
    catch {
        Write-ErrorHandler $_ "Failed to update Adobe Acrobat" -LogPath $LogPath
        return $false
    }
    finally {
        # Cleanup
        if (Test-Path $updateFile) {
            Remove-Item $updateFile -Force -ErrorAction SilentlyContinue
        }
    }
} 