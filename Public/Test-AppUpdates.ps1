function Test-AppUpdates {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$Applications,
        
        [Parameter()]
        [switch]$All,

        [Parameter()]
        [string]$LogPath,

        [Parameter()]
        [switch]$Silent
    )
    
    try {
        # Check admin rights first
        if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            throw "This function requires administrative rights"
        }

        # Check and install prerequisites
        $prereqMessage = "Installing required prerequisites (winget and osquery)"
        if ($Silent -or $PSCmdlet.ShouldContinue($prereqMessage, "Install Prerequisites")) {
            Write-AppLog "Checking prerequisites..." -LogPath $LogPath
            Install-Prerequisites
        }
        else {
            throw "Prerequisites check cancelled by user"
        }

        if ($All) {
            $Applications = (Get-AppConfig).PSObject.Properties.Name
        }
        
        $results = @()
        
        foreach ($app in $Applications) {
            $config = Get-AppConfig -Application $app
            if (-not $config) {
                Write-Warning "Application '$app' is not supported"
                continue
            }
            
            # Check for updates using winget
            $updateAvailable = winget upgrade --id $config.wingetId | Select-String "No applicable upgrade"
            
            $results += [PSCustomObject]@{
                Name = $app
                DisplayName = $config.displayName
                UpdateAvailable = ($null -eq $updateAvailable)
            }
        }
        
        return $results
    }
    catch {
        Write-ErrorHandler $_ "Failed in Test-AppUpdates" -LogPath $LogPath -ThrowError
    }
} 