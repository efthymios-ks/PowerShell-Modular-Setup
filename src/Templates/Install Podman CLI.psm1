# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
	Import-Module $_.FullName
}

function Get-ModuleName {
	return "Install Podman CLI"
}

function Test-Execute {
	$podmanPath = Get-Command "podman" -ErrorAction SilentlyContinue
	if ($podmanPath) {
		Write-Host "Podman CLI is already installed"
		return $false
	}

	Write-Host "Podman CLI is not installed"
	return $true
}

function Test-Restart {
	return $false
}

function Execute {
	$chocoCommand = "choco install podman-cli -f -y"
	$isOk, $message = Invoke-ChocoCommand $chocoCommand
	if (-not $isOk) {
		throw $message
	}

	Sync-ChocoEnv
	Write-Host "Podman CLI installation succeeded"
}

Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute
