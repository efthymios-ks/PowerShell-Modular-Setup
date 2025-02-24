# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
	Import-Module $_.FullName
}

function Get-ModuleName {
	return "Install Chocolatey"
}

function Test-Execute {
	$chocoPath = Get-Command choco -ErrorAction SilentlyContinue
	if ( -not $chocoPath) {
		Write-Line "Chocolatey is not installed"
		return $true
	}

	Write-Line "Chocolatey is already installed"
	return $false
}

function Test-Restart {
	return $true
}

function Execute {
	Write-Line "Installing Chocolatey..."
	$installScript = "https://chocolatey.org/install.ps1"
	Invoke-WebRequest -Uri $installScript -OutFile "$env:TEMP\install.ps1"
	Invoke-Expression -Command "$env:TEMP\install.ps1"

	Invoke-ChocoCommand "choco feature enable --name=""exitOnRebootDetected"""
}

Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute