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
    
    # Create module directory
    New-Item -Path $modulePath -ItemType Directory -Force | Out-Null
    
    # Download and extract
    Write-Verbose "Downloading module files..."
    $url = "https://github.com/jeremyroe/PSAppUpdates/archive/refs/heads/$Branch.zip"
    $output = Join-Path $env:TEMP "PSAppUpdates.zip"
    
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $output
    
    Write-Verbose "Extracting files..."
    Expand-Archive -Path $output -DestinationPath $env:TEMP -Force
    
    # Important: Copy from the correct subdirectory
    $extractPath = "$env:TEMP\PSAppUpdates-$Branch"
    Write-Verbose "Copying from: $extractPath"
    
    # Copy files from the correct location
    Copy-Item "$extractPath\*.ps*" $modulePath
    Copy-Item "$extractPath\Public" $modulePath -Recurse
    Copy-Item "$extractPath\Private" $modulePath -Recurse
    Copy-Item "$extractPath\Config" $modulePath -Recurse
    
    # Cleanup
    Remove-Item $output -Force -ErrorAction SilentlyContinue
    Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
    
    # Import module
    Write-Verbose "Loading module..."
    Import-Module PSAppUpdates -Force
    
    Write-Host "PSAppUpdates module installed successfully!" -ForegroundColor Green
    Write-Host "Use 'Test-AppUpdates -All -Verbose' to test the module" -ForegroundColor Yellow
}
catch {
    Write-Error "Failed to install PSAppUpdates: $_"
} 