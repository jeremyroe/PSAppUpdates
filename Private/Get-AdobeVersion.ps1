function Get-AdobeVersion {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$LogPath
    )
    
    try {
        # Get installed version using OSQuery
        $query = "SELECT name, version FROM programs WHERE name LIKE '%Adobe Acrobat%DC%' AND publisher = 'Adobe Systems Incorporated';"
        $result = & osqueryi --json "$query" | ConvertFrom-Json
        
        if (-not $result) {
            Write-AppLog "Adobe Acrobat DC not found" -LogPath $LogPath
            return $null
        }
        
        # Get latest version from Adobe's site
        $response = Invoke-WebRequest -Uri "https://www.adobe.com/devnet-docs/acrobatetk/tools/ReleaseNotesDC/continuous.html"
        if ($response.StatusCode -eq 200) {
            # Extract version from release notes page (format: Version 24.001.20615)
            if ($response.Content -match 'Version (\d+\.\d+\.\d+)') {
                $latestVersion = $Matches[1]
                
                $versionInfo = @{
                    Installed = $result.version
                    Latest = $latestVersion
                    NeedsUpdate = [version]$result.version -lt [version]$latestVersion
                }

                Write-AppLog "Adobe versions - Installed: $($versionInfo.Installed), Latest: $($versionInfo.Latest)" -LogPath $LogPath
                return $versionInfo
            }
        }
        
        throw "Could not determine latest Adobe version"
    }
    catch {
        Write-ErrorHandler $_ "Error checking Adobe version" -LogPath $LogPath
        return $null
    }
} 