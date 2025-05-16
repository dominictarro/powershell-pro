<#
.SYNOPSIS
    Lists and optionally clones missing GitHub repositories from an organization or team.

.DESCRIPTION
    This script compares local repositories in a specified directory against repositories in a GitHub organization 
    or team, identifying which ones are missing locally. It can optionally clone the missing repositories.

.PARAMETER Org
    The GitHub organization name to check repositories from.

.PARAMETER GitHubRoot
    The local directory path where repositories are stored.

.PARAMETER Team
    Optional. The team name within the organization to check repositories from.
    If not specified, checks all repositories in the organization.

.PARAMETER Clone
    Optional switch. If specified, missing repositories will be cloned to the GitHubRoot directory.

.EXAMPLE
    .\Missing-Repos.ps1 -Org "MyOrg" -GitHubRoot "C:\Repos"

.EXAMPLE
    .\Missing-Repos.ps1 -Org "MyOrg" -GitHubRoot "C:\Repos" -Team "DevTeam" -Clone
#>
param (
    [string]$Org,
    [string]$GitHubRoot,
    [Parameter(Mandatory = $false)]
    [string]$Team = "",
    [Parameter(Mandatory = $false)]
    [switch]$Clone
)

# Ensure GitHub CLI is available
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error "GitHub CLI (gh) is not installed or not in PATH."
    exit 1
}

# Ensure target folder exists
if (-not (Test-Path $GitHubRoot)) {
    Write-Error "Repository folder '$GitHubRoot' does not exist."
    exit 1
}

# Get local folder names
$localFolders = Get-ChildItem -Path $GitHubRoot -Directory | Select-Object -ExpandProperty Name

if (-not $Team) {
    # Fetch list of repositories from GitHub
    Write-Host "Fetching repositories for organization '$Org' from GitHub..."
    $repoNames = gh repo list "$Org" --limit 1000 --json name -q '.[].name'
} else {
    $teamSlug = $Team.ToLower().Replace(" ", "-")
    Write-Host "Fetching repositories for team '$Team' in org '$Org'..."
    # Fetch repositories the team has access to
    $apiUrl = "orgs/$Org/teams/$teamSlug/repos"
    $repoNames = gh api "$apiUrl" --paginate --jq '.[].name'
}

if (-not $repoNames) {
    Write-Error "Failed to fetch repositories or none found."
    exit 1
}

# Compare and find missing repositories
$missingRepos = @()
foreach ($repo in $repoNames) {
    if (-not ($localFolders -contains $repo)) {
        $missingRepos += $repo
    }
}

# Sort the missing repositories alphabetically
$missingRepos = $missingRepos | Sort-Object

# Output missing repos and optionally clone them
if ($missingRepos.Count -eq 0) {
    Write-Host "All repositories are present in '$GitHubRoot'."
} else {
    Write-Host "Missing repositories in '$GitHubRoot':"
    $missingRepos | ForEach-Object { 
        Write-Host "- $_"
        if ($Clone) {
            Write-Host "Cloning $_..."
            Push-Location $GitHubRoot
            gh repo clone "$Org/$_"
            Pop-Location
        }
    }
}
