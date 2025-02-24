# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
	Import-Module $_.FullName
}

function Get-ModuleName {
	return "Install Git"
}

function Test-Execute {
	$gitPath = Get-Command git -ErrorAction SilentlyContinue
	if ($gitPath) {
		Write-Line "Git is already installed"
		return $false
	}

	Write-Line "Git is not installed"
	return $true
}

function Test-Restart {
	return $false
}

function Execute {
	$chocoCommand = "choco install git -y -f"
	$isOk, $message = Invoke-ChocoCommand $chocoCommand
	if (-not $isOk) {
		throw $message
	}

	Sync-ChocoEnv
	Write-Line "Git installation succeeded"
}

Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute
