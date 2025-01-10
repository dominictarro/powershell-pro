<#
.SYNOPSIS
    Loads environment variables from a specified .env file into the current PowerShell session.

.DESCRIPTION
    This script reads a .env file and sets each valid key-value pair as an environment variable
    in the current PowerShell session. It supports commented lines (starting with #), handles
    empty lines, and can process values with or without quotes. The Select parameter supports glob patterns.

.PARAMETER Path
    The path to the .env file to load. This is a positional parameter.

.PARAMETER ListOnly
    If specified, only lists the environment variable names found in the file without setting them.

.PARAMETER Select
    Specify one or more variable names or patterns to load. If not specified, all variables will be loaded.
    Supports glob patterns like "*", "?", and "[]".
    Can be used multiple times, e.g., -Select "TEST_*","DEV_*"

.EXAMPLE
    .\Set-EnvFromFile.ps1 .env
    Loads all environment variables from a .env file in the current directory.

.EXAMPLE
    .\Set-EnvFromFile.ps1 .env -Select "TEST_*","DEV_*_SNOWFLAKE_*"
    Loads all variables starting with TEST_ and matching DEV_*_SNOWFLAKE_* pattern.

.EXAMPLE
    .\Set-EnvFromFile.ps1 .env -Select "DB_*" -ListOnly
    Lists all environment variable names that start with DB_ found in the file.

.NOTES
    File format should be:
    KEY=VALUE
    # Comments are supported
    QUOTED_VALUE="my value"

.OUTPUTS
    Writes success/failure messages to the host.
    Sets environment variables at the Process level (unless -ListOnly is specified).
#>

param(
    [Parameter(Position=0, Mandatory=$true)]
    [string]$Path,
    
    [Parameter()]
    [switch]$ListOnly,

    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Select
)

# Function to validate .env file exists
function Test-EnvFile {
    if (-not (Test-Path $Path)) {
        throw "Environment file not found at path: $Path"
    }
    if (-not ($Path -match '\.env$')) {
        throw "File must have .env extension"
    }
}

# Function to check if a key matches any of the glob patterns
function Test-KeyMatchesPattern {
    param(
        [string]$Key,
        [string[]]$Patterns
    )

    foreach ($pattern in $Patterns) {
        if ($Key -like $pattern) {
            return $true
        }
    }
    return $false
}

# Function to parse and set environment variables
function Set-EnvVariables {
    param(
        [switch]$ListOnly,
        [string[]]$Select
    )

    $envContent = Get-Content $Path
    $varsFound = @()
    
    # Process the Select array to remove "-Select" entries
    if ($Select) {
        $Select = $Select | Where-Object { $_ -ne "-Select" }
    }

    foreach ($line in $envContent) {
        # Skip empty lines and comments
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) {
            continue
        }

        # Split on first equals sign
        $keyValue = $line -split '=', 2
        if ($keyValue.Length -eq 2) {
            $key = $keyValue[0].Trim()
            $value = $keyValue[1].Trim()

            # Check if we should process this variable using glob patterns
            if ($Select -and -not (Test-KeyMatchesPattern -Key $key -Patterns $Select)) {
                continue
            }

            if ($ListOnly) {
                Write-Host $key
            }
            else {
                # Remove surrounding quotes if they exist
                $value = $value -replace '^["'']|["'']$'

                # Set the environment variable
                [System.Environment]::SetEnvironmentVariable($key, $value, 'Process')
                Write-Host "Set environment variable: $key"
                $varsFound += $key
            }
        }
        else {
            Write-Warning "Skipping invalid line: $line"
        }
    }

    # Warn if no variables were found matching any pattern
    if ($Select -and -not $ListOnly -and $varsFound.Count -eq 0) {
        Write-Warning "No variables found matching the specified patterns: $($Select -join ', ')"
    }
}

try {
    Test-EnvFile
    Set-EnvVariables -ListOnly:$ListOnly -Select $Select
    if (-not $ListOnly) {
        Write-Host "Environment variables loaded successfully from $Path"
    }
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}