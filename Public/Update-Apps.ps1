function Update-Apps {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [string[]]$Applications,
        
        [Parameter()]
        [string]$LogPath,
        
        [Parameter()]
        [int]$MaxRetries = 3,
        
        [Parameter()]
        [switch]$Force,
        
        [Parameter()]
        [switch]$ForceClose,
        
        [Parameter()]
        [switch]$All,

        [Parameter()]
        [switch]$Silent
    )

    try {
        # Check admin rights first
        if (-not (Test-AdminRights)) {
            throw "This function requires administrative rights"
        }

        # Check and install prerequisites
        $prereqMessage = "Installing required prerequisites (winget and osquery)"
        if ($Silent -or $PSCmdlet.ShouldProcess($prereqMessage, "Install Prerequisites")) {
            Write-AppLog "Checking prerequisites..." -LogPath $LogPath
            Install-Prerequisites
        }
        else {
            throw "Prerequisites check cancelled by user"
        }

        # If -All is specified, get all supported applications
        if ($All) {
            $Applications = (Get-AppConfig).PSObject.Properties.Name
        }

        foreach ($app in $Applications) {
            $config = Get-AppConfig -Application $app
            if (-not $config) {
                Write-Warning "Application '$app' is not supported"
                continue
            }

            if ($PSCmdlet.ShouldProcess($config.displayName, "Update application")) {
                Update-AppGeneric -Config $config -Force:$Force -ForceClose:$ForceClose -MaxRetries $MaxRetries -LogPath $LogPath
            }
        }
    }
    catch {
        Write-ErrorHandler $_ "Failed in Update-Apps" -LogPath $LogPath -ThrowError
    }
} 

<#
.SYNOPSIS
    Updates specified Windows applications using winget.

.DESCRIPTION
    Updates one or more supported Windows applications using winget. Supports automatic
    prerequisite installation, process handling, and detailed logging.

.PARAMETER Applications
    Array of application names to update. Use Get-SupportedApps to see available applications.

.PARAMETER LogPath
    Path to log file. If not specified, only console output is provided.

.PARAMETER MaxRetries
    Maximum number of retry attempts for failed updates. Default is 3.

.PARAMETER Force
    Forces the update even if the application is current.

.PARAMETER ForceClose
    Closes running applications before updating.

.PARAMETER All
    Updates all supported applications.

.PARAMETER Silent
    Suppresses confirmation prompts.

.EXAMPLE
    Update-Apps -All
    Updates all supported applications with confirmation prompts.

.EXAMPLE
    Update-Apps -Applications "Chrome","Firefox" -Force -LogPath "C:\Logs\Updates.log"
    Forces update of Chrome and Firefox with logging.

.EXAMPLE
    Update-Apps -All -Silent -ForceClose
    Updates all applications silently, closing running applications if needed.

.NOTES
    Requires administrative rights and Windows Package Manager (winget).
#> 