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
    
    # Create module files directly
    Write-Verbose "Creating module files..."
    
    # Create PSAppUpdates.psm1
    @'
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
'@ | Set-Content "$modulePath\PSAppUpdates.psm1"
    
    # Create PSAppUpdates.psd1
    @'
@{
    RootModule = 'PSAppUpdates.psm1'
    ModuleVersion = '0.1.0'
    GUID = '03d7882e-f245-4de8-9a13-65c67b4746e5'
    Author = 'Jeremy Roe'
    Description = 'Windows Application Update Management Module using Chocolatey and osquery'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Test-AppUpdates', 'Update-Apps', 'Get-SupportedApps')
}
'@ | Set-Content "$modulePath\PSAppUpdates.psd1"
    
    # Download and extract function files
    $url = "https://github.com/jeremyroe/PSAppUpdates/archive/refs/heads/$Branch.zip"
    $output = Join-Path $env:TEMP "PSAppUpdates.zip"
    
    Write-Verbose "Downloading from $url"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $output
    
    Write-Verbose "Extracting module files..."
    Expand-Archive -Path $output -DestinationPath $env:TEMP -Force
    
    $extractPath = "$env:TEMP\PSAppUpdates-$Branch"
    
    # Create directories and copy files
    foreach ($dir in @('Public', 'Private', 'Config')) {
        Write-Verbose "Processing $dir directory"
        $targetDir = "$modulePath\$dir"
        New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
        
        if (Test-Path "$extractPath\$dir") {
            Copy-Item "$extractPath\$dir\*" "$targetDir\" -Recurse -Force
            Get-ChildItem $targetDir -File | ForEach-Object { 
                Write-Verbose "  Copied $($_.Name)"
            }
        }
    }
    
    # Cleanup
    Write-Verbose "Cleaning up temporary files"
    Remove-Item $output -Force -ErrorAction SilentlyContinue
    Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
    
    # Verify structure
    Write-Verbose "Module structure:"
    Get-ChildItem $modulePath -Recurse | ForEach-Object {
        $indent = "  " * ($_.FullName.Split('\').Count - $modulePath.Split('\').Count)
        Write-Verbose "$indent$($_.Name)"
    }
    
    # Import module
    Write-Verbose "Loading module..."
    Import-Module PSAppUpdates -Force -Verbose -ErrorAction Stop
    
    Write-Host "PSAppUpdates module installed successfully!" -ForegroundColor Green
    Write-Host "Use 'Test-AppUpdates -All -Verbose' to test the module" -ForegroundColor Yellow
}
catch {
    Write-Error "Failed to install PSAppUpdates: $_"
    Write-Verbose "Stack trace:"
    Write-Verbose $_.ScriptStackTrace
} 