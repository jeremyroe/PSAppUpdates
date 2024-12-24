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
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            $null = Get-Command choco -ErrorAction Stop
            Write-Verbose "Chocolatey installed successfully"
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
            $result = choco upgrade osquery -y
            if ($result -match "upgraded (\d+)/(\d+) packages") {
                Write-Verbose "OSQuery updated successfully"
            }
            else {
                Write-Warning "OSQuery update may have failed. Please check version manually."
            }
        }
        else {
            Write-Verbose "OSQuery is up to date"
        }
    }
    catch {
        Write-Warning "OSQuery not found or update failed. Installing..."
        try {
            $result = choco install osquery -y
            Write-Verbose $result
        }
        catch {
            throw "Failed to install OSQuery: $_"
        }
    }
} 