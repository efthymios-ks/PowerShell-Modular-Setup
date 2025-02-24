# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
	Import-Module $_.FullName
}

function Get-ModuleName {
	return "Install Podman Desktop"
}

function Test-Execute {
 $podmanDesktopPaths = @(
		"$env:LOCALAPPDATA\Programs\podman-desktop\Podman Desktop.exe"
	)

	foreach ($path in $podmanDesktopPaths) {
		if (Test-Path $path) {
			Write-Host "Podman Desktop is already installed"
			return $false
		}
	}

	Write-Host "Podman Desktop is not installed"
	return $true
}


function Test-Restart {
	return $false
}

function Execute {
	$chocoCommand = "choco install podman-desktop -f -y"
	$isOk, $message = Invoke-ChocoCommand $chocoCommand
	if (-not $isOk) {
		throw $message
	}

	Write-Host "Podman Desktop installation succeeded"
}

Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute
