# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
    Import-Module $_.FullName
}

function Get-ModuleName {
    return "Install SSMS"
}

function Test-Execute {
    $ssmsPath = Get-Package -Name "Microsoft SQL Server Management Studio*" -ErrorAction SilentlyContinue
    if ($ssmsPath) {
        Write-Line "SSMS is already installed"
        return $false
    }

    Write-Line "SSMS is not installed"
    return $true
}

function Test-Restart {
    return $false
}

function Execute {
    $chocoCommand = "choco install sql-server-management-studio -y -f"
    $isOk, $message = Invoke-ChocoCommand $chocoCommand
    if (-not $isOk) {
        throw $message
    }

    Sync-ChocoEnv
    Write-Line "SSMS installation succeeded"
}

Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute
