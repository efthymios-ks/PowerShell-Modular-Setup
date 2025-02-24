# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
	Import-Module $_.FullName
}

function Get-ModuleName {
	return "Install Microsoft Teams"
}

function Test-Execute {
	$teamsPaths = @(
		"$env:LOCALAPPDATA\Microsoft\Teams\current\Teams.exe",
		"$env:PROGRAMFILES\Microsoft\Teams\current\Teams.exe",
		"$env:PROGRAMFILES(X86)\Microsoft\Teams\current\Teams.exe"
	)

	foreach ($path in $teamsPaths) {
		if (Test-Path $path) {
			Write-Host "Microsoft Teams is already installed"
			return $false
		}
	}

	Write-Host "Microsoft Teams is not installed"
	return $true
}

function Test-Restart {
	return $false
}

function Execute {
	$chocoCommand = "choco install microsoft-teams -f -y"
	$isOk, $message = Invoke-ChocoCommand $chocoCommand
	if (-not $isOk) {
		throw $message
	}

	Write-Host "Microsoft Teams installation succeeded"
}

Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute
