# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
	Import-Module $_.FullName
}

function Get-ModuleName {
	return "Install Docker"
}

function Test-Execute {
	$dockerPath = Get-Command docker -ErrorAction SilentlyContinue
	if ($dockerPath) {
		Write-Line "Docker is already installed"
		return $false
	}

	Write-Line "Docker is not installed"
	return $true
}

function Test-Restart {
	return $true
}

function Execute {
	$chocoCommand = "choco install docker-desktop -y -f"
	$isOk, $message = Invoke-ChocoCommand $chocoCommand
	if (-not $isOk) {
		throw $message
	}

	Sync-ChocoEnv

	Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform

	Write-Line "Docker installation succeeded"
}

Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute
