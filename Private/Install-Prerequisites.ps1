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
        $osqueryCmd = Get-Command osqueryi -ErrorAction Stop
        if ($osqueryCmd) {
            $currentVersion = & osqueryi --version
            Write-Verbose "Found OSQuery version: $currentVersion"
            
            # Get latest version from osquery.io
            $latestVersion = (Invoke-RestMethod -Uri "https://api.github.com/repos/osquery/osquery/releases/latest").tag_name
            $latestVersion = $latestVersion.TrimStart('v')
            Write-Verbose "Latest OSQuery version available: $latestVersion"
            
            if ([version]$currentVersion -ge [version]$latestVersion) {
                Write-Verbose "OSQuery is up to date"
                return
            }
            Write-Verbose "OSQuery needs updating from $currentVersion to $latestVersion"
        }
    }
    catch {
        Write-Warning "OSQuery not found or version check failed. Installing..."
        try {
            # Verify admin rights first
            if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
                throw "Administrator rights required for osquery installation"
            }

            # Get latest version and download URL
            $latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/osquery/osquery/releases/latest"
            $latestVersion = $latestRelease.tag_name.TrimStart('v')
            $osqueryUrl = "https://pkg.osquery.io/windows/osquery-$latestVersion.msi"
            Write-Verbose "Installing latest version: $latestVersion"

            # Check for existing installation and uninstall if needed
            $existingOsquery = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*osquery*" }
            if ($existingOsquery) {
                Write-Verbose "Found existing osquery installation. Attempting to uninstall..."
                $uninstallResult = $existingOsquery.Uninstall()
                if ($uninstallResult.ReturnValue -ne 0) {
                    throw "Failed to uninstall existing osquery version"
                }
                Write-Verbose "Successfully uninstalled existing osquery"
            }

            Write-Verbose "Installing osquery via direct MSI download..."
            $osqueryMsi = Join-Path $env:TEMP "osquery.msi"
            
            Write-Verbose "Downloading osquery MSI..."
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $osqueryUrl -OutFile $osqueryMsi
            
            Write-Verbose "Installing osquery..."
            $logFile = Join-Path $env:TEMP "osquery_install.log"
            $installArgs = "/i `"$osqueryMsi`" /qn /l*v `"$logFile`""
            
            try {
                $process = Start-Process "msiexec.exe" -ArgumentList $installArgs -Wait -PassThru -Verb RunAs
                
                if ($process.ExitCode -ne 0) {
                    $logContent = Get-Content $logFile -ErrorAction SilentlyContinue
                    Write-Verbose "MSI Log: $logContent"
                    throw "MSI installation failed with exit code $($process.ExitCode). Check log: $logFile"
                }
            }
            finally {
                if (Test-Path $osqueryMsi) {
                    Remove-Item $osqueryMsi -Force
                }
            }
            
            Write-Verbose "Refreshing environment path..."
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            
            # Verify installation
            Write-Verbose "Verifying osquery installation..."
            $null = Get-Command osqueryi -ErrorAction Stop
            Write-Verbose "OSQuery installed successfully"
        }
        catch {
            throw "Failed to install osquery: $_"
        }
    }
} 