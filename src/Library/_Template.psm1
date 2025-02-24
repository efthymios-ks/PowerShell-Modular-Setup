# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
	Import-Module $_.FullName
}

function Get-ModuleName {
	return "Module Name"
}

function Test-Execute {
	return $false
}

function Test-Restart {
	return $false
}

function Execute {
}

Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute