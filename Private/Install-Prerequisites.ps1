function Install-Prerequisites {
    [CmdletBinding()]
    param()
    
    Write-Verbose "Checking prerequisites..."
    
    # Check for Chocolatey
    try {
        $null = Get-Command choco -ErrorAction Stop
        Write-Verbose "Chocolatey is installed"
    }
    catch {
        Write-Warning "Chocolatey not found. Installing..."
        try {
            # Install Chocolatey (avoid variable conflicts)
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            
            # Use direct invocation instead of Invoke-Expression
            $installScript = (New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')
            & ([scriptblock]::Create($installScript))
            
            # Verify installation
            $null = Get-Command choco -ErrorAction Stop
            Write-Verbose "Chocolatey installed successfully"
            
            # Refresh environment
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        }
        catch {
            throw "Failed to install Chocolatey: $_"
        }
    }
    
    # Check for osquery and update if needed
    try {
        $osqueryPath = "${env:ProgramFiles}\osquery"
        if (Test-Path "${env:ProgramFiles(x86)}\osquery") {
            $osqueryPath = "${env:ProgramFiles(x86)}\osquery"
        }
        
        $osqueryExe = Join-Path $osqueryPath "osqueryi.exe"
        if (-not (Test-Path $osqueryExe)) {
            throw "OSQuery not found"
        }
        
        # Check version and update if needed
        $currentVersion = (& $osqueryExe --version).Replace('osqueryi.exe version ', '')
        Write-Verbose "Found OSQuery version: $currentVersion"
        
        $latestVersion = (Invoke-RestMethod -Uri "https://api.github.com/repos/osquery/osquery/releases/latest").tag_name.TrimStart('v')
        Write-Verbose "Latest OSQuery version available: $latestVersion"
        
        if ([version]$currentVersion -lt [version]$latestVersion) {
            Write-Verbose "OSQuery needs updating from $currentVersion to $latestVersion"
            try {
                $result = choco upgrade osquery -y
                
                # Verify the update
                $newVersion = (& $osqueryExe --version).Replace('osqueryi.exe version ', '')
                if ([version]$newVersion -gt [version]$currentVersion) {
                    Write-Verbose "OSQuery updated successfully from $currentVersion to $newVersion"
                }
                else {
                    Write-Warning "OSQuery update may have failed. Version is still $newVersion"
                    # Give time for processes to release handles
                    Start-Sleep -Seconds 2
                    # Try one more time
                    $result = choco upgrade osquery -y --force
                    $finalVersion = (& $osqueryExe --version).Replace('osqueryi.exe version ', '')
                    if ([version]$finalVersion -gt [version]$currentVersion) {
                        Write-Verbose "OSQuery updated successfully on second attempt to $finalVersion"
                    }
                    else {
                        Write-Warning "OSQuery update failed. Please update manually."
                    }
                }
            }
            catch {
                Write-Warning "Failed to update OSQuery: $_"
            }
        }
        else {
            Write-Verbose "OSQuery is up to date"
        }
    }
    catch {
        Write-Warning "OSQuery not found or update failed. Installing..."
        try {
            # Capture and format the output properly
            $chocoOutput = choco install osquery -y
            
            # Check if installation was successful
            if ($LASTEXITCODE -eq 0) {
                Write-Verbose "OSQuery installed successfully"
                Write-Verbose ($chocoOutput -join "`n")
            }
            else {
                throw "Chocolatey installation failed with exit code: $LASTEXITCODE"
            }
        }
        catch {
            $errorMsg = if ($_.Exception.Message) { $_.Exception.Message } else { "Unknown error during OSQuery installation" }
            throw "Failed to install OSQuery: $errorMsg"
        }
    }
} 