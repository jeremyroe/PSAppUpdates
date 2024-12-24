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
        # Get test results first
        $testResults = Test-AppUpdates -Applications $Applications -All:$All -Silent
        
        # Filter for only apps that need updates
        $updatesNeeded = $testResults | Where-Object { $_.UpdateAvailable }
        
        if (-not $updatesNeeded -or $updatesNeeded.Count -eq 0) {
            Write-Verbose "No updates required"
            return
        }

        # Show what we're going to do
        Write-Verbose "`nUpdate Summary:"
        foreach ($app in $updatesNeeded) {
            Write-Verbose "  $($app.DisplayName): Update available"
        }

        # Confirm all updates
        if (-not $Force) {
            $updateList = $updatesNeeded | ForEach-Object { $_.DisplayName }
            $message = "The following applications will be updated:`n" + ($updateList -join "`n")
            if (-not $PSCmdlet.ShouldProcess($message, "Update Applications")) {
                Write-Verbose "Update cancelled by user"
                return
            }
        }

        # Perform updates
        foreach ($app in $updatesNeeded) {
            $config = Get-AppConfig -Application $app.Name
            if ($PSCmdlet.ShouldProcess($app.DisplayName, "Update application")) {
                Write-Verbose "Updating $($app.DisplayName)..."
                try {
                    # Use Chocolatey to update
                    $result = choco upgrade $config.packageId -y
                    Write-Verbose $result
                }
                catch {
                    Write-Warning "Failed to update $($app.DisplayName): $_"
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