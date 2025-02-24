# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
    Import-Module $_.FullName
}

$SourceConnectionString = 'Server=.; Database=TestDB; User Id=sa; Password=1234; Encrypt=False; Trusted_Connection=True;'
$TargetConnectionString = 'Server=.; Database=TestDB2; User Id=sa; Password=1234; Encrypt=False; Trusted_Connection=True;'

function Get-ModuleName {
    return "Clone MSSQL database"
}

function Test-Execute {
    $sqlPackagePath = Get-Command "sqlpackage" -ErrorAction SilentlyContinue
    if (-not $sqlPackagePath) {
        throw "sqlpackage not found. Please install to proceed."
    }

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

function Backup-Database {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ConnectionString,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath
    )

    $arguments = @(
        "/Action:Export"
        "/SourceConnectionString:`"$ConnectionString`""
        "/TargetFile:`"$OutputPath`""
        "/OverwriteFiles:True"
        "/Quiet:True"
    )

    $argumentsAsString = $arguments -join " "

    Write-Host "Executing 'sqlpackage $argumentsAsString'"
    $process = Start-Process -FilePath "sqlpackage" -ArgumentList $argumentsAsString -Wait -NoNewWindow -PassThru
    if ($process.ExitCode -ne 0) {
        throw "sqlpackage export failed with exit code $($proc.ExitCode)."
    }
}

function Restore-Database {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ConnectionString,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$InputPath
    )

    $arguments = @(
        "/Action:Import"
        "/TargetConnectionString:`"$ConnectionString`""
        "/SourceFile:`"$InputPath`""
        "/Quiet:True"
    )

    $argumentsAsString = $arguments -join " "

    Write-Host "Executing 'sqlpackage $argumentsAsString'"
    $process = Start-Process -FilePath "sqlpackage" -ArgumentList $argumentsAsString -Wait -NoNewWindow -PassThru
    if ($process.ExitCode -ne 0) {
        throw "sqlpackage import failed with exit code $($proc.ExitCode)."
    }
}

function Execute {
    # Generate temp backup file path
    $tempBackupPath = [System.IO.Path]::Combine("C:\Temp", "db_clone_$([System.Guid]::NewGuid()).bacpac")

    # Extract database names from connection strings
    $sourceDb = Get-MsSqlDatabaseNameFromConnectionString -ConnectionString $SourceConnectionString
    $targetDb = Get-MsSqlDatabaseNameFromConnectionString -ConnectionString $TargetConnectionString
    Write-Host "Source Database: '$sourceDb'"
    Write-Host "Target Database: '$targetDb'"
    Write-Host "Temporary backup file: '$tempBackupPath'"

    # Backup source database
    Write-Host "Starting database backup..."
    Backup-Database -ConnectionString $SourceConnectionString -OutputPath $tempBackupPath
    Write-Host "Backup successfully!"

    try {
        # Restore backup to target database
        Write-Host "Starting database restore..."
        Restore-Database -ConnectionString $TargetConnectionString -InputPath $tempBackupPath
        Write-Host "Restored successfully!"
    }
    catch {
        Write-Host "Failed to restore database"
        throw $_
    }
    finally {
        # Remove temporary backup file
        Write-Host "Removing temporary backup file..."
        Remove-Item -Path $tempBackupPath -Force
        Write-Host "Removed successfully!"
    }

    Write-Host "Database cloning completed successfully."
}

Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute
