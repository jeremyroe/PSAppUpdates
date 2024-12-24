# PSAppUpdates

Manage Windows application updates using Chocolatey and OSQuery. This PowerShell module provides simple commands to check and install updates for common Windows applications.

## Quick Install

```powershell
# Install directly from GitHub (requires admin rights)
irm https://raw.githubusercontent.com/jeremyroe/PSAppUpdates/main/Install.ps1 | iex
```n
## Basic Commands

Check for updates:
```powershell
# Check all applications
Test-AppUpdates -All -Verbose

# Check specific application
Test-AppUpdates -Applications "Chrome"
```n
Install updates:
```powershell
# Update all applications
Update-Apps -All -Verbose

# Update specific application
Update-Apps -Applications "Chrome"

# Preview updates without installing
Update-Apps -All -WhatIf
```n
## Requirements

- Windows PowerShell 5.1+
- Administrator rights
- Internet connectivity

The module automatically installs and maintains:
- Chocolatey package manager
- OSQuery (latest version)

## Currently Supported Apps

- Google Chrome

## Common Parameters

- -Verbose: Show detailed progress
- -WhatIf: Preview changes
- -LogPath: Specify log file
- -Force: Skip prompts

## Example Workflow

1. Check for updates:
```powershell
Test-AppUpdates -All -Verbose
```n
2. Review available updates:
```powershell
Update-Apps -All -WhatIf
```n
3. Install updates:
```powershell
Update-Apps -All -Verbose
```n
## Features

- Automatic prerequisite installation
- Process handling for running apps
- Detailed logging
- Update verification
- Version comparison
