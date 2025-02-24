# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
	Import-Module $_.FullName
}

function Get-ModuleName {
	return "Install Mozilla Firefox"
}

function Test-Execute {
	$firefoxExe = "$Env:ProgramFiles\Mozilla Firefox\firefox.exe"
	if (Test-Path $firefoxExe) {
		Write-Line "Mozilla Firefox is already installed"
		return $false
	}

	Write-Line "Mozilla Firefox is not installed"
	return $true
}

function Test-Restart {
	return $false
}

function Execute {
	$chocoCommand = "choco install firefox -y -f"
	$isOk, $message = Invoke-ChocoCommand $chocoCommand
	if (-not $isOk) {
		throw $message
	}

	Write-Line "Mozilla Firefox installation succeeded"
}

Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute
