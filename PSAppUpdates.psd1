@{
    RootModule = 'PSAppUpdates.psm1'
    ModuleVersion = '0.1.0'
    GUID = '03d7882e-f245-4de8-9a13-65c67b4746e5'  # Will generate new GUID
    Author = 'Jeremy Roe'
    Description = 'Windows Application Update Management Module using Chocolatey and osquery'
    PowerShellVersion = '5.1'
    RequiredModules = @()
    FunctionsToExport = @(
        'Test-AppUpdates',
        'Update-Apps',
        'Get-SupportedApps'
    )
    PrivateData = @{
        PSData = @{
            Tags = @('Windows', 'Updates', 'Applications', 'Winget', 'OSQuery')
            ProjectUri = 'https://github.com/jeremyroe/PSAppUpdates'
            LicenseUri = 'https://github.com/jeremyroe/PSAppUpdates/blob/main/LICENSE'
        }
    }
} 