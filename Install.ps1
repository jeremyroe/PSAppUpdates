[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

Write-Verbose "Installing PSAppUpdates module..."

# Set module path
$modulePath = "$env:ProgramFiles\WindowsPowerShell\Modules\PSAppUpdates"
Write-Verbose "Module path: $modulePath"

# Create module directory
if (Test-Path $modulePath) {
    Remove-Item $modulePath -Recurse -Force
}
New-Item -ItemType Directory -Path $modulePath -Force | Out-Null

# Download and extract module files
Write-Verbose "Downloading module files..."
$branch = "feature/adobe-acrobat-updates"  # Specify branch here
$zipUrl = "https://github.com/jeremyroe/PSAppUpdates/archive/refs/heads/$branch.zip"
$zipFile = Join-Path $env:TEMP "PSAppUpdates.zip"

Invoke-WebRequest -Uri $zipUrl -OutFile $zipFile
Write-Verbose "Extracting files..."
Expand-Archive -Path $zipFile -DestinationPath $env:TEMP -Force

# Copy files to module directory
Write-Verbose "Copying from: $env:TEMP\PSAppUpdates-$branch"
Copy-Item "$env:TEMP\PSAppUpdates-$branch\*" $modulePath -Recurse -Force

# Clean up
Remove-Item $zipFile -Force
Remove-Item "$env:TEMP\PSAppUpdates-$branch" -Recurse -Force

# Load module
Write-Verbose "Loading module..."
Import-Module PSAppUpdates -Force

Write-Host "PSAppUpdates module installed successfully!"
Write-Host "Use 'Test-AppUpdates -All -Verbose' to test the module" 