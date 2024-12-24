function Update-Apps {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [string[]]$Applications,
        
        [Parameter()]
        [switch]$All,

        [Parameter()]
        [string]$LogPath,

        [Parameter()]
        [switch]$Force
    )
    
    try {
        Write-Verbose "Checking prerequisites..."
        Install-Prerequisites
        
        # Get applications to check
        if ($All) {
            $Applications = (Get-AppConfig).PSObject.Properties.Name
        }
        
        $updatesNeeded = @()
        foreach ($app in $Applications) {
            $config = Get-AppConfig -Application $app
            if (-not $config) {
                Write-Warning "Application '$app' not supported"
                continue
            }
            
            # Check if installed and needs update
            $installed = choco list $config.packageId --local-only -r
            if (-not $installed) {
                Write-Verbose "$($config.displayName) is not installed - skipping"
                continue
            }
            
            # Get current version
            $currentVersion = ($installed -split '\|')[1]
            Write-Verbose "$($config.displayName) current version: $currentVersion"
            
            # Special handling for OSQuery version check
            if ($app -eq 'OSQuery') {
                # Get latest version from GitHub
                $latestVersion = (Invoke-RestMethod -Uri "https://api.github.com/repos/osquery/osquery/releases/latest").tag_name.TrimStart('v')
                Write-Verbose "Latest OSQuery version available: $latestVersion"
                
                if ([version]$currentVersion -lt [version]$latestVersion) {
                    Write-Verbose "$($config.displayName) has update available: $currentVersion -> $latestVersion"
                    $updatesNeeded += @{
                        Name = $app
                        DisplayName = $config.displayName
                        PackageId = $config.packageId
                        CurrentVersion = $currentVersion
                        AvailableVersion = $latestVersion
                    }
                }
                continue
            }
            
            # Regular Chocolatey version check for other apps
            $outdated = choco outdated $config.packageId -r
            if ($outdated -match $config.packageId) {
                # Parse the outdated string correctly
                $outdatedParts = $outdated -split '\|'
                if ($outdatedParts.Count -ge 4) {
                    $availableVersion = $outdatedParts[3].Trim()
                    if ([string]::IsNullOrEmpty($availableVersion) -or $availableVersion -eq 'false') {
                        Write-Verbose "$($config.displayName) has no valid update version available"
                        continue
                    }
                    Write-Verbose "$($config.displayName) has update available: $currentVersion -> $availableVersion"
                    $updatesNeeded += @{
                        Name = $app
                        DisplayName = $config.displayName
                        PackageId = $config.packageId
                        CurrentVersion = $currentVersion
                        AvailableVersion = $availableVersion
                    }
                }
                else {
                    Write-Warning "Could not parse update information for $($config.displayName)"
                    continue
                }
            }
            else {
                Write-Verbose "$($config.displayName) is up to date (version $currentVersion)"
            }
        }
        
        if (-not $updatesNeeded) {
            Write-Verbose "No updates required"
            return
        }

        # Show what we're going to do
        Write-Verbose "`nUpdate Summary:"
        foreach ($app in $updatesNeeded) {
            Write-Verbose "  $($app.DisplayName): $($app.CurrentVersion) -> $($app.AvailableVersion)"
        }

        # Perform updates
        foreach ($app in $updatesNeeded) {
            if ($PSCmdlet.ShouldProcess($app.DisplayName, "Update from $($app.CurrentVersion) to $($app.AvailableVersion)")) {
                Write-Verbose "Updating $($app.DisplayName)..."
                try {
                    $result = choco upgrade $app.PackageId -y
                    Write-Verbose $result
                }
                catch {
                    Write-Warning "Failed to update $($app.DisplayName): $($_.Exception.Message)"
                }
            }
        }
    }
    catch {
        Write-ErrorHandler $_ "Failed in Update-Apps" -LogPath $LogPath -ThrowError
    }
} 

<#
.SYNOPSIS
    Updates specified Windows applications using Chocolatey.

.DESCRIPTION
    Updates one or more supported Windows applications using Chocolatey. Supports automatic
    prerequisite installation, process handling, and detailed logging.

.PARAMETER Applications
    Array of application names to update. Use Get-SupportedApps to see available applications.

.PARAMETER All
    Updates all supported applications.

.PARAMETER LogPath
    Path to log file. If not specified, only console output is provided.

.PARAMETER Force
    Forces the update without confirmation prompts.

.EXAMPLE
    Update-Apps -All
    Updates all supported applications with confirmation prompts.

.EXAMPLE
    Update-Apps -Applications "Chrome" -Force -LogPath "C:\Logs\Updates.log"
    Forces update of Chrome with logging.

.NOTES
    Requires administrative rights and Chocolatey package manager.
#> 
#> 