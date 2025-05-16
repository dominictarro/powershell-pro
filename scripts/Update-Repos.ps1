<#
.SYNOPSIS
    Updates all Git repositories in a directory by pulling the latest changes from main.

.DESCRIPTION
    This script iterates through all directories in a specified path, checks if they are Git repositories,
    switches to the main branch, pulls the latest changes, and optionally returns to the original branch.

.PARAMETER GitHubRoot
    The root directory containing Git repositories to update.

.PARAMETER NoReturn
    Optional switch. If specified, repositories will remain on the main branch after updating.
    If not specified, repositories return to their original branch after pulling from main.

.EXAMPLE
    .\Update-Repos.ps1 -GitHubRoot "C:\Repos"

.EXAMPLE
    .\Update-Repos.ps1 -GitHubRoot "C:\Repos" -NoReturn
#>
param (
    [Parameter(Mandatory = $true)]
    [string]$GitHubRoot,

    [switch]$NoReturn
)

# Ensure the path exists
if (-Not (Test-Path -Path $GitHubRoot)) {
    Write-Host "The specified path does not exist: $GitHubRoot" -ForegroundColor Red
    exit 1
}

# Get starting location
$startLocation = Get-Location

# Get all directories inside the GitHub root
$repoDirs = Get-ChildItem -Path $GitHubRoot -Directory

foreach ($repo in $repoDirs) {
    Write-Host "`n--- Processing repo: $($repo.FullName) ---"

    Set-Location $repo.FullName

    try {
        git rev-parse --is-inside-work-tree | Out-Null
    } catch {
        Write-Host "Not a git repository: $($repo.FullName)" -ForegroundColor Yellow
        continue
    }

    # Get the current branch
    try {
        $currentBranch = git rev-parse --abbrev-ref HEAD
        Write-Host "Current branch: $currentBranch"
    } catch {
        Write-Host "Failed to get current branch in $($repo.FullName): $_" -ForegroundColor Red
        continue
    }

    # Checkout main
    try {
        git checkout main 2>&1 | Write-Host
    } catch {
        Write-Host "Failed to checkout main in $($repo.FullName): $_" -ForegroundColor Red
        continue
    }

    # Pull latest changes from main
    try {
        git pull origin main 2>&1 | Write-Host
    } catch {
        Write-Host "Failed to pull from main in $($repo.FullName): $_" -ForegroundColor Red
    }

    # Checkout back to original branch if NoReturn is false
    try {
        if (-not $NoReturn -and $currentBranch -ne 'main') {
            git checkout $currentBranch 2>&1 | Write-Host
        }
    } catch {
        Write-Host "Failed to return to original branch '$currentBranch' in $($repo.FullName): $_" -ForegroundColor Red
    }
}

# Return to original location
Set-Location $startLocation
