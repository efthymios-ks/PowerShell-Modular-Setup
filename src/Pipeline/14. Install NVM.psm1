# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
	Import-Module $_.FullName
}

# Leave empty for latest version
$TargetVersion = ""

function Get-ModuleName {
	$name = "Install NVM"
	if ($TargetVersion) {
		$name += " ($TargetVersion)"
	}

	return $name
}

function Test-Execute {
	$nvmPath = Get-Command nvm -ErrorAction SilentlyContinue
	if (-not $nvmPath) {
		Write-Line "NVM is not installed"
		return $true
	}

	$installedVersion = nvm version 2>$null
	if (-not $TargetVersion) {
		Write-Line "NVM ($installedVersion) is already installed"
		return $false
	}

	if ($installedVersion -ne $TargetVersion) {
		Write-Line "NVM version mismatch. Installed: $installedVersion, Target: $TargetVersion"
		return $true
	}

	Write-Line "NVM ($installedVersion) is already installed"
	return $false
}

function Test-Restart {
	return $false
}

function Execute {
	$chocoCommand = "choco install nvm -y -f --allow-downgrade"
	if ($TargetVersion) {
		$chocoCommand += " --version=$TargetVersion"
	}

	$isOk, $message = Invoke-ChocoCommand $chocoCommand
	if (-not $isOk) {
		throw $message
	}

	Sync-ChocoEnv

	if ($TargetVersion) {
		nvm install $TargetVersion
		nvm use $TargetVersion
	}
	else {
		nvm install latest
		nvm use latest
	}

	Write-Line "NVM installation succeeded"
}

Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute