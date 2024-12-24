[CmdletBinding()]
param(
    [Parameter()]
    [string]$Branch = "main"
)

try {
    Write-Verbose "Installing PSAppUpdates module..."
    
    # Install to system-wide location
    $modulePath = "$env:ProgramFiles\WindowsPowerShell\Modules\PSAppUpdates"
    Write-Verbose "Module path: $modulePath"
    
    # Clean up any existing installation
    if (Test-Path $modulePath) {
        Write-Verbose "Removing existing installation"
        Remove-Item $modulePath -Recurse -Force
    }
    
    # Download and extract
    Write-Verbose "Downloading module files..."
    $url = "https://github.com/jeremyroe/PSAppUpdates/archive/refs/heads/$Branch.zip"
    $output = Join-Path $env:TEMP "PSAppUpdates.zip"
    
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $output
    
    Write-Verbose "Extracting files..."
    Expand-Archive -Path $output -DestinationPath $env:TEMP -Force
    $extractPath = "$env:TEMP\PSAppUpdates-$Branch"
    
    # Copy entire module structure
    Write-Verbose "Copying module files..."
    Copy-Item -Path $extractPath -Destination $modulePath -Recurse -Force
    
    # Verify structure
    Write-Verbose "`nVerifying module structure:"
    Get-ChildItem $modulePath -Recurse | ForEach-Object {
        Write-Verbose "  $($_.FullName)"
    }
    
    # Import module
    Write-Verbose "`nImporting module..."
    Import-Module -Name PSAppUpdates -Force -Verbose
    
    Write-Host "PSAppUpdates module installed successfully!" -ForegroundColor Green
    Write-Host "Use 'Test-AppUpdates -All -Verbose' to test the module" -ForegroundColor Yellow
}
catch {
    Write-Error "Failed to install PSAppUpdates: $_"
    Write-Verbose "Stack trace:"
    Write-Verbose $_.ScriptStackTrace
} 