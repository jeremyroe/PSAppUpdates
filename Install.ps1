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
$branch = "feature/adobe-acrobat-updates"
$branchPath = $branch.Replace('/', '-')  # Fix path issues
$zipUrl = "https://github.com/jeremyroe/PSAppUpdates/archive/refs/heads/$branch.zip"
$zipFile = Join-Path $env:TEMP "PSAppUpdates.zip"

Invoke-WebRequest -Uri $zipUrl -OutFile $zipFile
Write-Verbose "Extracting files..."
Expand-Archive -Path $zipFile -DestinationPath $env:TEMP -Force

# Copy files to module directory
$sourcePath = Join-Path $env:TEMP "PSAppUpdates-$branchPath"
Write-Verbose "Copying from: $sourcePath"
Copy-Item "$sourcePath\*" $modulePath -Recurse -Force

# Clean up
Remove-Item $zipFile -Force -ErrorAction SilentlyContinue
Remove-Item $sourcePath -Recurse -Force -ErrorAction SilentlyContinue

# Load module
Write-Verbose "Loading module..."
Import-Module PSAppUpdates -Force

Write-Host "PSAppUpdates module installed successfully!"
Write-Host "Use 'Test-AppUpdates -All -Verbose' to test the module" 