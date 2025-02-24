# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
    Import-Module $_.FullName
}

function Get-ModuleName {
    return "Install SqlPackage"
}

function Test-Execute {
    $sqlPackagePath = Get-Command "sqlpackage" -ErrorAction SilentlyContinue
    if ($sqlPackagePath) {
        Write-Host "SqlPackage is already installed"
        return $false
    }

    Write-Host "SqlPackage is not installed"
    return $true
}

function Test-Restart {
    return $false
}

function Execute {
    $chocoCommand = "choco install sqlpackage -y -f"
    $isOk, $message = Invoke-ChocoCommand $chocoCommand
    if (-not $isOk) {
        throw $message
    }

    Sync-ChocoEnv
    Write-Line "SqlPackage installation succeeded"
}

Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute
