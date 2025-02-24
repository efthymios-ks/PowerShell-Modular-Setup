# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
  Import-Module $_.FullName
}

function Get-ModuleName {
  return "Install Visual Studio 2022 Community Edition"
}

function Test-Execute {
  $vsWherePath = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"

  if (-Not (Test-Path $vsWherePath)) {
    Write-Host "vswhere.exe not found. Visual Studio is likely also missing."
    return $true
  }

  $vsInstalled = & $vsWherePath -format json -version "17" -products "Microsoft.VisualStudio.Product.Community"
  if ($vsInstalled) {
    Write-Host "Visual Studio 2022 Community Edition is already installed"
    return $false
  }

  Write-Host "Visual Studio 2022 Community Edition is not installed"
  return $true
}

function Test-Restart {
  return $true
}

function Execute {
  $chocoCommand = @"
      choco install visualstudio2022community -f -y --package-parameters `"`
        --quiet `
        --norestart `
        --installWhileDownloading `
        --add Microsoft.VisualStudio.Workload.NetWeb `
        --add Microsoft.VisualStudio.Workload.ManagedDesktop `
        --includeRecommended
      `"
"@
  $chocoCommand = $chocoCommand -replace '(\r|\n)', ' '
  $chocoCommand = $chocoCommand -replace '\s+', ' '
  $chocoCommand = $chocoCommand.trim()

  $isOk, $message = Invoke-ChocoCommand $chocoCommand
  if (-not $isOk) {
    throw $message
  }

  Write-Host "Visual Studio 2022 Community Edition installation succeeded"
}

Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute
