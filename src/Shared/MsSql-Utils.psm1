function Invoke-MsSql {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConnectionString,

        [Parameter(Mandatory = $true)]
        [string]$SQL
    )

    $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
    $command = $connection.CreateCommand()
    $command.CommandText = $SQL

    try {
        $connection.Open()
        Write-Host "Executing query: '$SQL'"
        $result = $command.ExecuteNonQuery()
        return $result
    }
    finally {
        $connection.Close()
    }
}

function Invoke-MsSqlScalar {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ConnectionString,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SQL
    )

    $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
    $command = $connection.CreateCommand()
    $command.CommandText = $SQL

    try {
        $connection.Open()
        Write-Host "Executing scalar query: '$SQL'"
        $result = $command.ExecuteScalar()
        return $result
    }
    finally {
        $connection.Close()
    }
}

function Get-MsSqlDatabaseNameFromConnectionString {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ConnectionString
    )

    if ($ConnectionString -match "(?i)(?:Initial Catalog|Database)=([^;]+)") {
        return $matches[1]
    }

    throw "Invalid connection string: Missing 'Initial Catalog' or 'Database'"
}

function Remove-MsSqlDatabaseFromConnectionString {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $ConnectionString
    )

    $ConnectionString = $ConnectionString -replace "([;]?(Initial Catalog|Database)=[^;]+)", ""
    if ($ConnectionString.EndsWith(";")) {
        $ConnectionString = $ConnectionString.TrimEnd(";")
    }

    return $ConnectionString
}

function Test-MsSqlDatabaseExists {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $ConnectionString
    )

    $databaseName = Get-MsSqlDatabaseNameFromConnectionString -ConnectionString $ConnectionString
    $connectionStringWithoutDatabase = Remove-MsSqlDatabaseFromConnectionString -ConnectionString $ConnectionString
    $sql = "SELECT COUNT(*) FROM sys.databases WHERE name = N'$databaseName'"
    $databaseCount = Invoke-MsSqlScalar -ConnectionString $connectionStringWithoutDatabase -SQL $sql
    return $databaseCount -gt 0
}

Export-ModuleMember -Function Invoke-MsSql,
Invoke-MsSqlScalar,
Get-MsSqlDatabaseNameFromConnectionString,
Remove-MsSqlDatabaseFromConnectionString,
Test-MsSqlDatabaseExists