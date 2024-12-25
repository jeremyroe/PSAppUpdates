function Update-AdobeAcrobat {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$CurrentVersion,
        
        [Parameter(Mandatory)]
        [string]$TargetVersion
    )
    
    try {
        Write-Verbose "Preparing Adobe Acrobat DC update..."
        
        # Get update URL from Adobe's site
        $updateUrl = "https://ardownload2.adobe.com/pub/adobe/acrobat/win/AcrobatDC/$TargetVersion/AcroRdrDCUpd$TargetVersion.msp"
        $updateFile = Join-Path $env:TEMP "AcrobatUpdate.msp"
        
        # Download update
        Write-Verbose "Downloading update package..."
        Invoke-WebRequest -Uri $updateUrl -OutFile $updateFile
        
        if (-not (Test-Path $updateFile)) {
            throw "Failed to download update package"
        }
        
        # Check running processes
        $processes = Get-Process -Name "Acrobat", "AcroRd32" -ErrorAction SilentlyContinue
        if ($processes) {
            Write-Warning "Adobe Acrobat processes found running. Please save work and close them."
            return $false
        }
        
        # Install update
        if ($PSCmdlet.ShouldProcess("Adobe Acrobat DC", "Update from $CurrentVersion to $TargetVersion")) {
            Write-Verbose "Installing update..."
            $result = Start-Process -FilePath "msiexec.exe" -ArgumentList "/p `"$updateFile`" /qn" -Wait -PassThru
            
            if ($result.ExitCode -eq 0) {
                Write-Verbose "Update installed successfully"
                return $true
            }
            else {
                throw "Update installation failed with exit code: $($result.ExitCode)"
            }
        }
        
        return $false
    }
    catch {
        Write-Warning "Failed to update Adobe Acrobat: $_"
        return $false
    }
    finally {
        # Cleanup
        if (Test-Path $updateFile) {
            Remove-Item $updateFile -Force -ErrorAction SilentlyContinue
        }
    }
} 