@{
    # Core module settings
    RootModule = 'PSAppUpdates.psm1'
    ModuleVersion = '0.1.0'
    GUID = '03d7882e-f245-4de8-9a13-65c67b4746e5'
    
    # Author information
    Author = 'Jeremy Roe'
    Description = 'Windows Application Update Management Module using Chocolatey and osquery'
    
    # Minimum PowerShell version required
    PowerShellVersion = '5.1'
    
    # Module dependencies
    RequiredModules = @()
    
    # Functions to make available to users
    FunctionsToExport = @(
        'Test-AppUpdates',
        'Update-Apps',
        'Get-SupportedApps'
    )
    
    # Additional metadata for PowerShell Gallery
    PrivateData = @{
        PSData = @{
            Tags = @(
                'Windows',
                'Updates',
                'Applications',
                'Chocolatey',
                'OSQuery'
            )
            ProjectUri = 'https://github.com/jeremyroe/PSAppUpdates'
            LicenseUri = 'https://github.com/jeremyroe/PSAppUpdates/blob/main/LICENSE'
        }
    }
} 