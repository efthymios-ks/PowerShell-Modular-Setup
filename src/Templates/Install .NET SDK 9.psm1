# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
  Import-Module $_.FullName
}

function Get-ModuleName {
  return "Install .NET SDK 9"
}

function Test-Execute {
  $dotnetPath = Get-Command "dotnet" -ErrorAction SilentlyContinue
  if (-not $dotnetPath) {
    Write-Host ".NET SDK 9 is not installed"
    return $true
  }

  $dotnetSdks = & "dotnet" --list-sdks -ErrorAction SilentlyContinue
  if ($dotnetSdks -and $dotnetSdks -match "9\.0\.\d+") {
    Write-Host ".NET SDK 9 is already installed"
    return $false
  }

  Write-Host ".NET SDK 9 is not installed"
  return $true
}

function Test-Restart {
  return $false
}

function Execute {
  $chocoCommand = "choco install dotnet-9.0-sdk -y -f"
  $isOk, $message = Invoke-ChocoCommand $chocoCommand
  if (-not $isOk) {
    throw $message
  }

  Sync-ChocoEnv
  Write-Line ".NET SDK 9 installation succeeded"
}

Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute
