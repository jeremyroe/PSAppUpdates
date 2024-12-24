function Install-Prerequisites {
    [CmdletBinding()]
    param()
    
    Write-Verbose "Checking prerequisites..."
    
    # Check for winget
    try {
        $null = Get-Command winget -ErrorAction Stop
        Write-Verbose "Winget is installed"
    }
    catch {
        Write-Warning "Winget not found. Installing..."
        try {
            $progressPreference = 'SilentlyContinue'
            Write-Verbose "Downloading Microsoft.DesktopAppInstaller..."
            $URL = "https://aka.ms/getwinget"
            $outputFile = Join-Path $env:TEMP "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
            Invoke-WebRequest -Uri $URL -OutFile $outputFile
            Add-AppxPackage -Path $outputFile
            Remove-Item $outputFile
        }
        catch {
            throw "Failed to install winget: $_"
        }
    }
    
    # Check for osquery
    try {
        $null = Get-Command osqueryi -ErrorAction Stop
        Write-Verbose "OSQuery is installed"
    }
    catch {
        Write-Warning "OSQuery not found. Installing..."
        try {
            # Use winget to install osquery with more specific parameters
            Write-Verbose "Attempting to install osquery via winget..."
            $result = winget install --exact --id "osquery.osquery" --accept-source-agreements --accept-package-agreements --silent
            
            if ($LASTEXITCODE -ne 0) {
                # Try alternative installation if winget fails
                Write-Verbose "Winget installation failed, attempting alternative installation..."
                $osqueryMsi = Join-Path $env:TEMP "osquery.msi"
                $osqueryUrl = "https://pkg.osquery.io/windows/osquery-5.9.1.msi"
                
                Invoke-WebRequest -Uri $osqueryUrl -OutFile $osqueryMsi
                $installArgs = "/i `"$osqueryMsi`" /qn"
                Start-Process "msiexec.exe" -ArgumentList $installArgs -Wait
                
                Remove-Item $osqueryMsi -Force
                
                # Verify installation
                $null = Get-Command osqueryi -ErrorAction Stop
            }
            
            # Refresh environment path
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        }
        catch {
            throw "Failed to install osquery: $_"
        }
    }
} 