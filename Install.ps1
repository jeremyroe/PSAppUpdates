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
    
    # Download and extract
    $url = "https://github.com/jeremyroe/PSAppUpdates/archive/refs/heads/$Branch.zip"
    $output = Join-Path $env:TEMP "PSAppUpdates.zip"
    
    Write-Verbose "Downloading from $url"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $output
    
    Write-Verbose "Extracting module files..."
    Expand-Archive -Path $output -DestinationPath $env:TEMP -Force
    
    # Copy files from the correct subdirectory
    $extractPath = "$env:TEMP\PSAppUpdates-$Branch"
    Write-Verbose "Copying files from $extractPath to $modulePath"
    
    # Copy module files
    Write-Verbose "Copying root module files"
    Copy-Item "$extractPath\*.ps*" $modulePath -Force
    Get-ChildItem $modulePath -File | ForEach-Object { Write-Verbose "  Copied $($_.Name)" }
    
    # Create subdirectories and copy files
    foreach ($dir in @('Public', 'Private', 'Config')) {
        if (Test-Path "$extractPath\$dir") {
            Write-Verbose "Processing $dir directory"
            $targetDir = "$modulePath\$dir"
            New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
            Copy-Item "$extractPath\$dir\*" "$targetDir\" -Recurse -Force
            Get-ChildItem $targetDir -File | ForEach-Object { Write-Verbose "  Copied $($_.Name)" }
        }
    }
    
    # Cleanup
    Write-Verbose "Cleaning up temporary files"
    Remove-Item $output -Force -ErrorAction SilentlyContinue
    Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
    
    # Import module
    Write-Verbose "Loading module..."
    Write-Verbose "Module files present:"
    Get-ChildItem $modulePath -Recurse | ForEach-Object { Write-Verbose "  $($_.FullName)" }
    
    Import-Module PSAppUpdates -Force -Verbose -ErrorAction Stop
    
    Write-Host "PSAppUpdates module installed successfully!" -ForegroundColor Green
    Write-Host "Use 'Test-AppUpdates -All -Verbose' to test the module" -ForegroundColor Yellow
}
catch {
    Write-Error "Failed to install PSAppUpdates: $_"
    Write-Verbose "Stack trace:"
    Write-Verbose $_.ScriptStackTrace
} 