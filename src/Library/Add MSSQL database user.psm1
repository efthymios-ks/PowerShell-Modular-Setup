# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
	Import-Module $_.FullName
}

$ConnectionString = 'Server=.; Database=TestDB; User Id=sa; Password=1234; Trusted_Connection=True;'
$Username = "makis"
$Password = "makis!1234"
$ShouldRecreate = $true

function Get-ModuleName {
	return "Add MSSQL database user"
}

function Test-Execute {
	$databaseExists = Test-MsSqlDatabaseExists -ConnectionString $ConnectionString
	if (!$databaseExists) {
		throw "Database does not exist."
	}

	if (-not $ShouldRecreate) {
		$connectionStringWithoutDatabase = Remove-MsSqlDatabaseFromConnectionString -ConnectionString $ConnectionString
		$sql = "SELECT COUNT(*) FROM sys.syslogins WHERE name = N'$Username';"
		$userCount = Invoke-MsSqlScalar -ConnectionString $connectionStringWithoutDatabase -SQL $sql
		if ($userCount -eq 0) {
			Write-Host "User '$Username' does not exist"
			return $true
		}

		Write-Host "User '$Username' already exists"
		return $false
	}

	Write-Host "Dropping -if existing- and recreating user '$Username'"
	return $true
}

function Test-Restart {
	return $false
}

function Execute {
	$sql = "IF EXISTS (SELECT * FROM sys.syslogins WHERE name = N'$Username') DROP LOGIN [$Username];"
	Invoke-MsSql -ConnectionString $ConnectionString -SQL $sql

	$databaseName = Get-MsSqlDatabaseNameFromConnectionString -ConnectionString $ConnectionString
	$sql = @"
		USE [$databaseName];
		IF EXISTS (SELECT * FROM sys.database_principals WHERE name = N'$Username') DROP USER [$Username];
		CREATE LOGIN [$Username] WITH PASSWORD=N'$Password';
		CREATE USER [$Username] FOR LOGIN [$Username];
		ALTER ROLE [db_owner] ADD MEMBER [$Username];
"@
	Invoke-MsSql -ConnectionString $ConnectionString -SQL $sql

	Write-Host "User '$Username' created successfully with password '$Password'."
}

Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute
