<#
.SYNOPSIS
    Lists GitHub repositories in an organization that have no team assignments.

.DESCRIPTION
    This script checks all repositories in a GitHub organization and identifies which ones
    do not have any teams assigned to them. This can help identify repositories that may
    need team access configured.

.PARAMETER Org
    The GitHub organization name to check repositories from.

.EXAMPLE
    .\Teamless-Repos.ps1 -Org "MyOrg"
#>
param (
    [string]$Org
)

# Ensure gh is installed
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error "GitHub CLI (gh) is not installed."
    exit 1
}

# Get all repositories for the organization
Write-Host "Fetching all repositories for org '$Org'..."
$repos = gh api "orgs/$Org/repos" --paginate --jq '.[].name'

if (-not $repos) {
    Write-Error "No repositories found or error fetching repos."
    exit 1
}

$reposWithoutTeams = @()

foreach ($repo in $repos) {
    Write-Host "Checking teams for repository '$repo'..."
    $teams = gh api "repos/$Org/$repo/teams" --jq '.[].name' 2>$null

    if (-not $teams) {
        $reposWithoutTeams += $repo
    }
}

$reposWithoutTeams = $reposWithoutTeams | Sort-Object

# Output result
if ($reposWithoutTeams.Count -eq 0) {
    Write-Host "All repositories have team assignments."
} else {
    Write-Host "`nRepositories with NO team access:"
    $reposWithoutTeams | ForEach-Object { Write-Host "- $_" }
}
