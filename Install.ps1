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
    
    # Create fresh directory
    Write-Verbose "Creating module directory"
    New-Item -Path $modulePath -ItemType Directory -Force | Out-Null
    
    # Create PSAppUpdates.psm1 first
    Write-Verbose "Creating PSAppUpdates.psm1"
    $psm1Content = @'
# Get public and private function definition files
$Public = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)

# Dot source the files
foreach ($import in @($Public + $Private)) {
    try {
        . $import.FullName
    }
    catch {
        Write-Error "Failed to import function $($import.FullName): $_"
    }
}

# Export public functions
Export-ModuleMember -Function $Public.BaseName
'@
    $psm1Content | Set-Content "$modulePath\PSAppUpdates.psm1" -Encoding UTF8
    Write-Verbose "Created PSAppUpdates.psm1"
    
    # Create PSAppUpdates.psd1
    Write-Verbose "Creating PSAppUpdates.psd1"
    $psd1Content = @'
@{
    ModuleVersion = '0.1.0'
    GUID = '03d7882e-f245-4de8-9a13-65c67b4746e5'
    Author = 'Jeremy Roe'
    Description = 'Windows Application Update Management Module using Chocolatey and osquery'
    PowerShellVersion = '5.1'
    RootModule = 'PSAppUpdates.psm1'
    FunctionsToExport = @('Test-AppUpdates', 'Update-Apps', 'Get-SupportedApps')
}
'@
    $psd1Content | Set-Content "$modulePath\PSAppUpdates.psd1" -Encoding UTF8
    Write-Verbose "Created PSAppUpdates.psd1"
    
    # Download and extract function files
    Write-Verbose "Downloading module files..."
    $url = "https://github.com/jeremyroe/PSAppUpdates/archive/refs/heads/$Branch.zip"
    $output = Join-Path $env:TEMP "PSAppUpdates.zip"
    
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $output
    Write-Verbose "Downloaded to $output"
    
    Write-Verbose "Extracting files..."
    Expand-Archive -Path $output -DestinationPath $env:TEMP -Force
    $extractPath = "$env:TEMP\PSAppUpdates-$Branch"
    Write-Verbose "Extracted to $extractPath"
    
    # Create directories and copy files
    foreach ($dir in @('Public', 'Private', 'Config')) {
        Write-Verbose "Processing $dir directory"
        $targetDir = "$modulePath\$dir"
        New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
        Write-Verbose "Created $targetDir"
        
        if (Test-Path "$extractPath\$dir") {
            Copy-Item "$extractPath\$dir\*" "$targetDir\" -Recurse -Force
            Get-ChildItem $targetDir -File | ForEach-Object { 
                Write-Verbose "  Copied $($_.Name)"
            }
        }
    }
    
    # Verify structure before cleanup
    Write-Verbose "`nVerifying module structure:"
    Get-ChildItem $modulePath -Recurse | ForEach-Object {
        Write-Verbose "  $($_.FullName)"
    }
    
    # Test manifest before import
    Write-Verbose "`nTesting module manifest..."
    $manifest = Test-ModuleManifest "$modulePath\PSAppUpdates.psd1" -ErrorAction Stop
    Write-Verbose "Manifest test passed"
    
    # Import module
    Write-Verbose "`nImporting module..."
    Import-Module -Name PSAppUpdates -Force -Verbose -ErrorAction Stop
    Write-Verbose "Module imported successfully"
    
    Write-Host "PSAppUpdates module installed successfully!" -ForegroundColor Green
    Write-Host "Use 'Test-AppUpdates -All -Verbose' to test the module" -ForegroundColor Yellow
}
catch {
    Write-Error "Failed to install PSAppUpdates: $_"
    Write-Verbose "Stack trace:"
    Write-Verbose $_.ScriptStackTrace
} 