# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
	Import-Module $_.FullName
}

$ConnectionString = 'Server=.; User Id=sa; Password=1234; Trusted_Connection=True;'
$Sql = "IF EXISTS (SELECT * FROM sys.syslogins WHERE name = N'Makis') DROP LOGIN [Makis];"

function Get-ModuleName {
	return "Run MSSQL query"
}

function Test-Execute {
	return $true
}

function Test-Restart {
	return $false
}

function Execute {
	Invoke-MsSql -ConnectionString $ConnectionString -SQL $Sql

	Write-Host "Query executed successfully."
}

Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute
