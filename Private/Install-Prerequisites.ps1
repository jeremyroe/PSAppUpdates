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
            # Install Chocolatey (works in system context)
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            
            # Verify installation
            $null = Get-Command choco -ErrorAction Stop
            Write-Verbose "Chocolatey installed successfully"
        }
        catch {
            throw "Failed to install Chocolatey: $_"
        }
    }
    
    # Check for osquery
    try {
        $osqueryPath = "${env:ProgramFiles}\osquery"
        if (Test-Path "${env:ProgramFiles(x86)}\osquery") {
            $osqueryPath = "${env:ProgramFiles(x86)}\osquery"
        }
        
        $osqueryExe = Join-Path $osqueryPath "osqueryi.exe"
        if (-not (Test-Path $osqueryExe)) {
            throw "OSQuery not found"
        }
        Write-Verbose "OSQuery is installed"
    }
    catch {
        Write-Warning "OSQuery not found. Installing via Chocolatey..."
        try {
            $result = choco install osquery -y
            Write-Verbose $result
        }
        catch {
            throw "Failed to install OSQuery: $_"
        }
    }
} 