# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
	Import-Module $_.FullName
}

<#
	GitHub Access Token:
		- https://github.com/settings/tokens (basic)
#>

$RepoUrl = "https://github.com/efthymios-ks/PowerShell-Modular-Setup.git"
$DestinationPath = "C:\Repos\PowerShell-Modular-Setup"

function Get-ModuleName {
	return "Clone Repository"
}

function Test-Execute {
	$git = Get-Command git -ErrorAction SilentlyContinue
	if (-not $git) {
		throw "Git is not installed. Please install Git before running this module."
	}

	if (Test-Path $DestinationPath) {
		Write-Host "Repository already exists at '$DestinationPath'."
		return $false
	}

	Write-Host "Cloning repository from '$RepoUrl' to '$DestinationPath'."
	return $true
}

function Test-Restart {
	return $false
}

function Execute {
	Write-Host "Executing: 'git clone $RepoUrl $DestinationPath'"
	git clone $RepoUrl $DestinationPath
	if ($?) {
		Write-Host "Repository cloned successfully to $DestinationPath"
		return
	}

	Write-Host "Failed to clone repository"
}


Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute
