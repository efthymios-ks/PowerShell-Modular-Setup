# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
    Import-Module $_.FullName
}

$SourceConnectionString = 'Server=.; Database=TestDB; User Id=sa; Password=1234; Trusted_Connection=True;'
$TargetConnectionString = 'Server=.; Database=TestDB2; User Id=sa; Password=1234; Trusted_Connection=True;'

function Get-ModuleName {
    return "Clone MSSQL database"
}

function Test-Execute {
    $databaseExists = Test-MsSqlDatabaseExists -ConnectionString $SourceConnectionString
    if (!$databaseExists) {
        throw "Source database does not exist."
    }

    $databaseExists = Test-MsSqlDatabaseExists -ConnectionString $TargetConnectionString
    if ($databaseExists) {
        Write-Host "Target database already exists."
        return $false;
    }

    Write-Host "Target database does not exist."
    return $true
}

function Test-Restart {
    return $false
}

function Execute {
    # Generate temp backup file path
    $tempBackupPath = [System.IO.Path]::Combine("C:\Temp", "db_clone_$([System.Guid]::NewGuid()).bak")

    # Extract database names from connection strings
    $sourceDb = Get-MsSqlDatabaseNameFromConnectionString -ConnectionString $SourceConnectionString
    $targetDb = Get-MsSqlDatabaseNameFromConnectionString -ConnectionString $TargetConnectionString
    $TargetConnectionString = Remove-MsSqlDatabaseFromConnectionString -ConnectionString $TargetConnectionString
    Write-Host "Source Database: '$sourceDb'"
    Write-Host "Target Database: '$targetDb'"
    Write-Host "Temporary backup file: '$tempBackupPath'"

    # Backup source database
    Write-Host "Starting database backup..."
    Invoke-MsSqlCmd -ConnectionString $SourceConnectionString -SQL "BACKUP DATABASE [$sourceDb] TO DISK = '$tempBackupPath' WITH FORMAT, INIT"
    Write-Host "Backup successfully!"

    # Restore backup to target database
    Write-Host "Starting database restore..."
    Invoke-MsSqlCmd -ConnectionString $TargetConnectionString -SQL "RESTORE DATABASE [$targetDb] FROM DISK = '$tempBackupPath' WITH REPLACE, MOVE '$sourceDb' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\$targetDb.mdf', MOVE '${sourceDb}_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\$targetDb.ldf'"
    Write-Host "Restored successfully!"

    # Remove temporary backup file
    Write-Host "Removing temporary backup file..."
    Remove-Item -Path $tempBackupPath -Force
    Write-Host "Removed successfully!"

    Write-Host "Database cloning completed successfully."
}

Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute
