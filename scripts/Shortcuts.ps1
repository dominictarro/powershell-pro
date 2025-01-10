<#
.SYNOPSIS
Lists custom PowerShell scripts in ~/.local/bin with their descriptions.

.DESCRIPTION
Scans the ~/.local/bin directory for PowerShell scripts (.ps1 files) and creates a table
displaying each script's name and optionally its description. The descriptions are extracted
from each script's help documentation using Get-Help.

.PARAMETER ShowDescription
If specified, includes descriptions for each script by loading their help documentation.
This may increase execution time but provides more detailed information.

.EXAMPLE
PS> ./Shortcuts.ps1

Lists all scripts with their names only (fast).

.EXAMPLE
PS> ./Shortcuts.ps1 -ShowDescription

Lists all scripts with their names and help documentation descriptions (slower).

.NOTES
Author: PowerShell User
Version: 1.1
Last Updated: 2025-01-10

.LINK
https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/get-help
#>

[CmdletBinding()]
param(
    [switch]$ShowDescription
)

function Get-ScriptDescription {
    param (
        [string]$ScriptPath
    )
    
    try {
        # Get help information for the script
        $help = Get-Help $ScriptPath -ErrorAction Stop
        
        # Use Synopsis as the primary description
        if ($help.Synopsis -and -not [string]::IsNullOrWhiteSpace($help.Synopsis)) {
            return $help.Synopsis.Trim()
        }
        # Fall back to Description if Synopsis is empty
        elseif ($help.Description -and $help.Description.Text) {
            return $help.Description.Text.Trim()
        }
        else {
            return "No help documentation found"
        }
    }
    catch {
        return "No help documentation found"
    }
}

# Expand the ~/.local/bin path
$binPath = (Get-Item "~/.local/bin").FullName

# Get all PowerShell scripts
$scripts = Get-ChildItem -Path $binPath -Filter "*.ps1"

# Create an array to hold the table data
$tableData = @()

foreach ($script in $scripts) {
    $description = if ($ShowDescription) {
        Get-ScriptDescription -ScriptPath $script.FullName
    } else {
        ""
    }
    
    $tableData += [PSCustomObject]@{
        Command = $script.BaseName
        Description = $description
    }
}

# Output the table, hiding the Description column if it's empty
if ($ShowDescription) {
    $tableData | Format-Table -AutoSize -Wrap
} else {
    $tableData | Format-Table Command -AutoSize
}