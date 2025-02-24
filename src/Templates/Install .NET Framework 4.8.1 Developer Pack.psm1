# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
  Import-Module $_.FullName
}

function Get-ModuleName {
  return "Install .NET Framework 4.8.1 Developer Pack"
}

function Test-Execute {
  $dotnetFrameworkRelease = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -Name Release -ErrorAction SilentlyContinue).Release

  <#
    533320 (Windows 10/11) → .NET Framework 4.8.1 is installed
    528040 (Windows 10/11) → .NET Framework 4.8 is installed
  #>

  if ($dotnetFrameworkRelease -ge 533320) {
    Write-Host ".NET Framework 4.8.1 Developer Pack is already installed"
    return $false
  }

  Write-Host ".NET Framework 4.8.1 Developer Pack is not installed"
  return $true
}

function Test-Restart {
  return $true
}

function Execute {
  $chocoCommand = "choco install netfx-4.8.1-devpack -y -f"
  $isOk, $message = Invoke-ChocoCommand $chocoCommand
  if (-not $isOk) {
    throw $message
  }

  Sync-ChocoEnv
  Write-Line ".NET Framework 4.8.1 Developer Pack installation succeeded"
}

Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute
