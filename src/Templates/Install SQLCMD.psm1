# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
  Import-Module $_.FullName
}

function Get-ModuleName {
  return "Install SQLCMD"
}

function Test-Execute {
  $sqlcmdPath = Get-Command sqlcmd -ErrorAction SilentlyContinue
  if ($sqlcmdPath) {
    Write-Line "SQLCMD is already installed"
    return $false
  }

  Write-Line "SQLCMD is not installed"
  return $true
}

function Test-Restart {
  return $true
}

function Execute {
  $chocoCommand = "choco install sqlcmd -y -f"
  $isOk, $message = Invoke-ChocoCommand $chocoCommand
  if (-not $isOk) {
    throw $message
  }

  Write-Line "SQLCMD installation succeeded"
}

Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute
