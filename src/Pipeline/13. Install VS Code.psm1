# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
  Import-Module $_.FullName
}

function Get-ModuleName {
  return "Install Visual Studio Code"
}

function Test-Execute {
  $vsCodePath = Get-Command "code" -ErrorAction SilentlyContinue
  if ($vsCodePath) {
    Write-Host "Visual Studio Code is already installed"
    return $false
  }

  Write-Host "Visual Studio Code is not installed"
  return $true
}

function Test-Restart {
  return $true
}

function Execute {
  $chocoCommand = "choco install vscode -f -y"
  $isOk, $message = Invoke-ChocoCommand $chocoCommand
  if (-not $isOk) {
    throw $message
  }

  Sync-ChocoEnv
  Write-Host "Visual Studio Code installation succeeded"
}

Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute
