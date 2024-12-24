[CmdletBinding()]
param(
    [Parameter()]
    [string]$Branch = "main"
)

# Ensure we're running as admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "This script requires administrative rights. Please run PowerShell as Administrator."
}

try {
    Write-Verbose "Installing PSAppUpdates module..."
    
    # Install to system-wide location instead of user profile
    $modulePath = "$env:ProgramFiles\WindowsPowerShell\Modules\PSAppUpdates"
    if (-not (Test-Path $modulePath)) {
        New-Item -Path $modulePath -ItemType Directory -Force | Out-Null
    }

    # Download and extract
    $url = "https://github.com/jeremyroe/PSAppUpdates/archive/refs/heads/$Branch.zip"
    $output = Join-Path $env:TEMP "PSAppUpdates.zip"
    
    Write-Verbose "Downloading from $url"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $output
    
    Write-Verbose "Extracting to $modulePath"
    Expand-Archive -Path $output -DestinationPath $env:TEMP -Force
    Copy-Item "$env:TEMP\PSAppUpdates-$Branch\*" $modulePath -Recurse -Force
    
    # Cleanup
    Remove-Item $output -Force
    Remove-Item "$env:TEMP\PSAppUpdates-$Branch" -Recurse -Force
    
    Write-Verbose "Installation complete. Loading module..."
    Import-Module PSAppUpdates -Force
    
    Write-Host "PSAppUpdates module installed successfully!" -ForegroundColor Green
    Write-Host "Use 'Test-AppUpdates -All -Verbose' to test the module" -ForegroundColor Yellow
}
catch {
    Write-Error "Failed to install PSAppUpdates: $_"
} 