@{
    # Core module settings
    RootModule = 'PSAppUpdates.psm1'
    ModuleVersion = '0.2.0'
    GUID = '03d7882e-f245-4de8-9a13-65c67b4746e5'
    Author = 'Jeremy Roe'
    Description = 'Windows Application Update Management Module supporting multiple update methods including Winget, Chocolatey, and vendor-specific updates'
    PowerShellVersion = '5.1'
    
    # Functions to export
    FunctionsToExport = @(
        'Test-AppUpdates',
        'Update-Apps',
        'Get-SupportedApps'
    )
} 