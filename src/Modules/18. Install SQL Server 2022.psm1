# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
    Import-Module $_.FullName
}

$ServerName = "MSSQLSERVER"
# Username = "sa" [Fixed]
$Password = "1234"

function Get-ModuleName {
    return "Install SQL Server 2022"
}

function Test-Execute {
    $sqlInstances = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL" -ErrorAction SilentlyContinue
    if ($sqlInstances -and $sqlInstances.PSObject.Properties.Name -contains $ServerName) {
        Write-Line "SQL Server instance '$ServerName' is already installed"
        return $false
    }

    Write-Line "SQL Server instance '$ServerName' is not installed"
    return $true
}

function Test-Restart {
    return $false
}

function Execute {
    function Add-WindowsLoginToSqlServer {
        $machineName = $env:COMPUTERNAME
        $userName = $env:USERNAME
        $windowsLogin = "$machineName\$userName"

        $connectionString = "Server=.; User Id=sa; Password=$Password;"
        $sql = "SELECT COUNT(*) FROM sys.server_principals WHERE name = '$windowsLogin'"
        $loginExists = Invoke-MsSqlScalar -ConnectionString $connectionString -SQL $sql
        if ($loginExists -eq "1") {
            Write-Host "Windows login '$windowsLogin' already exists in SQL Server"
            return
        }

        $sql = "CREATE LOGIN [$windowsLogin] FROM WINDOWS;
            ALTER SERVER ROLE sysadmin ADD MEMBER [$windowsLogin];"
        Invoke-MsSql -ConnectionString $connectionString -SQL $sql

        Write-Host "Added Windows login '$windowsLogin' as sysadmin"
    }

    $chocoCommand = "choco install sql-server-2022 -y -f --package-parameters '/INSTANCENAME=""$ServerName"" /SAPWD=""$Password"" /SQLSYSADMINACCOUNTS=BUILTIN\ADMINISTRATORS /SECURITYMODE=SQL'"
    $isOk, $message = Invoke-ChocoCommand $chocoCommand
    if (-not $isOk) {
        throw $message
    }

    Add-WindowsLoginToSqlServer

    # Set the SQL Server service to start automatically
    $serviceName = "$ServerName"
    Set-Service -Name $serviceName -StartupType Automatic
    Start-Service -Name $serviceName -ErrorAction SilentlyContinue

    Sync-ChocoEnv
    Write-Host "SQL Server installation succeeded"
}

Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute
