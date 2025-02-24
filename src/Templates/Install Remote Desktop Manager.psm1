# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
	Import-Module $_.FullName
}

function Get-ModuleName {
	return "Install Remote Desktop Manager"
}

function Test-Execute {
	$rdmPaths = @(
		"$env:PROGRAMFILES\Devolutions\Remote Desktop Manager\RDM.exe",
		"$env:PROGRAMFILES\Devolutions\Remote Desktop Manager\RemoteDesktopManager.exe",
		"$env:PROGRAMFILES(X86)\Devolutions\Remote Desktop Manager\RDM.exe"
		"$env:PROGRAMFILES(X86)\Devolutions\Remote Desktop Manager\RemoteDesktopManager.exe"
	)

	foreach ($path in $rdmPaths) {
		if (Test-Path $path) {
			Write-Host "Remote Desktop Manager is already installed"
			return $false
		}
	}

	Write-Host "Remote Desktop Manager is not installed"
	return $true
}

function Test-Restart {
	return $false
}

function Execute {
	$chocoCommand = "choco install rdm -f -y"
	$isOk, $message = Invoke-ChocoCommand $chocoCommand
	if (-not $isOk) {
		throw $message
	}

	Write-Host "Remote Desktop Manager installation succeeded"
}

Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute
