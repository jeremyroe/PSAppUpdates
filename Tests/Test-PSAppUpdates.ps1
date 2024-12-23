[CmdletBinding()]
param(
    [Parameter()]
    [string]$LogPath = ".\TestResults.log"
)

# Import module
try {
    Import-Module (Join-Path $PSScriptRoot ".." "PSAppUpdates.psd1") -Force
    Write-AppLog "Module imported successfully" -LogPath $LogPath
} catch {
    Write-ErrorHandler $_ "Failed to import module" -LogPath $LogPath -ThrowError
}

# Test cases
$tests = @(
    @{
        Name = "Prerequisites Check"
        Test = {
            Install-Prerequisites
            $winget = Get-Command winget -ErrorAction SilentlyContinue
            $osquery = Get-Command osqueryi -ErrorAction SilentlyContinue
            if (-not ($winget -and $osquery)) {
                throw "Prerequisites not installed"
            }
        }
    },
    @{
        Name = "Config Loading"
        Test = {
            $config = Get-AppConfig
            if (-not $config.AdobeReader) {
                throw "Failed to load application configuration"
            }
        }
    },
    @{
        Name = "Supported Apps List"
        Test = {
            $apps = Get-SupportedApps
            if ($apps.Count -eq 0) {
                throw "No supported applications found"
            }
        }
    },
    @{
        Name = "Update Check"
        Test = {
            $results = Test-AppUpdates -All
            if ($null -eq $results) {
                throw "Update check failed"
            }
        }
    },
    @{
        Name = "Admin Rights"
        Test = {
            if (-not (Test-AdminRights)) {
                throw "Test must run with admin rights"
            }
        }
    },
    @{
        Name = "Process Detection"
        Test = {
            $config = Get-AppConfig
            foreach ($app in $config.PSObject.Properties) {
                foreach ($process in $app.Value.processNames) {
                    if ([string]::IsNullOrEmpty($process)) {
                        throw "Invalid process name for $($app.Name)"
                    }
                }
            }
        }
    }
)

# Run tests
$results = @{
    Passed = 0
    Failed = 0
    Errors = @()
}

foreach ($test in $tests) {
    Write-AppLog "Running test: $($test.Name)" -LogPath $LogPath
    try {
        & $test.Test
        $results.Passed++
        Write-AppLog "Test passed: $($test.Name)" -LogPath $LogPath
    }
    catch {
        $results.Failed++
        $results.Errors += @{
            TestName = $test.Name
            Error = $_.Exception.Message
        }
        Write-ErrorHandler $_ "Test failed: $($test.Name)" -LogPath $LogPath
    }
}

# Report results
Write-AppLog "Test Results:" -LogPath $LogPath
Write-AppLog "Passed: $($results.Passed)" -LogPath $LogPath
Write-AppLog "Failed: $($results.Failed)" -LogPath $LogPath

if ($results.Failed -gt 0) {
    Write-AppLog "Failed Tests:" -LogPath $LogPath
    foreach ($error in $results.Errors) {
        Write-AppLog "  $($error.TestName): $($error.Error)" -Level Error -LogPath $LogPath
    }
    throw "One or more tests failed"
}

Write-AppLog "All tests completed successfully" -LogPath $LogPath 