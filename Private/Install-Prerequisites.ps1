function Install-Prerequisites {
    [CmdletBinding()]
    param()
    
    Write-Verbose "Checking prerequisites..."
    
    # Check for winget
    try {
        $wingetPath = "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe"
        
        # Get latest version folder
        $wingetDir = Get-ChildItem -Path $wingetPath -ErrorAction Stop | 
            Sort-Object LastWriteTime -Descending | 
            Select-Object -First 1
            
        if (-not $wingetDir) {
            throw "Winget installation not found"
        }

        # Ensure system account has access
        if ([System.Security.Principal.WindowsIdentity]::GetCurrent().IsSystem) {
            $acl = Get-Acl $wingetDir.FullName
            $systemSid = New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::LocalSystemSid, $null)
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($systemSid, "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
            
            if (-not ($acl.Access | Where-Object { $_.IdentityReference -eq $systemSid })) {
                $acl.AddAccessRule($rule)
                Set-Acl $wingetDir.FullName $acl
            }
        }

        $wingetExe = Join-Path $wingetDir.FullName "winget.exe"
        Write-Verbose "Using winget from: $wingetExe"
        $env:Path = "$($wingetDir.FullName);$env:Path"

        # Verify winget works
        $null = & $wingetExe --version
        Write-Verbose "Winget is operational"
    }
    catch {
        throw "Winget prerequisite not met: $_. Please ensure winget is installed system-wide via GPO/SCCM/Intune."
    }
    
    # Check for osquery
    try {
        $osqueryPath = "${env:ProgramFiles}\osquery"
        if (Test-Path "${env:ProgramFiles(x86)}\osquery") {
            $osqueryPath = "${env:ProgramFiles(x86)}\osquery"
        }
        
        $osqueryExe = Join-Path $osqueryPath "osqueryi.exe"
        if (Test-Path $osqueryExe) {
            # Get current version (strip 'osqueryi.exe version ' from start)
            $currentVersion = (& $osqueryExe --version).Replace('osqueryi.exe version ', '')
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
    
    # Check for Chocolatey
    try {
        $null = Get-Command choco -ErrorAction Stop
        Write-Verbose "Chocolatey is installed"
    }
    catch {
        Write-Warning "Chocolatey not found. Installing..."
        try {
            $installScript = Join-Path $env:TEMP "install-choco.ps1"
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        }
        catch {
            throw "Failed to install Chocolatey: $_"
        }
    }
} 