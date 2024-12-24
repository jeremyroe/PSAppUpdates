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
        $osqueryPath = "${env:ProgramFiles}\osquery"
        if (Test-Path "${env:ProgramFiles(x86)}\osquery") {
            $osqueryPath = "${env:ProgramFiles(x86)}\osquery"
        }
        
        $osqueryExe = Join-Path $osqueryPath "osqueryi.exe"
        if (Test-Path $osqueryExe) {
            $currentVersion = & $osqueryExe --version
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

                # Find osquery installation path
                Write-Verbose "Locating osquery installation..."
                $osqueryPath = "${env:ProgramFiles}\osquery"
                if (Test-Path "${env:ProgramFiles(x86)}\osquery") {
                    $osqueryPath = "${env:ProgramFiles(x86)}\osquery"
                }

                # Add to PATH if not already present
                $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
                if ($currentPath -notlike "*$osqueryPath*") {
                    Write-Verbose "Adding osquery to system PATH..."
                    $newPath = "$currentPath;$osqueryPath"
                    [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
                    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
                }

                # Verify installation using full path
                Write-Verbose "Verifying osquery installation..."
                $osqueryExe = Join-Path $osqueryPath "osqueryi.exe"
                if (-not (Test-Path $osqueryExe)) {
                    throw "Osquery executable not found at expected location: $osqueryExe"
                }
                
                # Test the installation
                $version = & $osqueryExe --version
                Write-Verbose "Osquery $version installed successfully at $osqueryPath"
            }
            finally {
                if (Test-Path $osqueryMsi) {
                    Remove-Item $osqueryMsi -Force
                }
            }
        }
        catch {
            throw "Failed to install osquery: $_"
        }
    }
} 