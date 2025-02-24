# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
  Import-Module $_.FullName
}

$DefaultFileExtensions = @(
  '.rar',
  '.zip'
)

$WinRARPath = "C:\Program Files\WinRAR\WinRAR.exe"

function Get-ModuleName {
  return "Install WinRAR"
}

function Test-Execute {
  if (Test-Path $WinRARPath) {
    Write-Host "WinRAR is already installed"
    return $false
  }

  Write-Host "WinRAR is not installed"
  return $true
}

function Test-Restart {
  return $true
}

function Execute {
  $chocoCommand = "choco install winrar -f -y"
  $isOk, $message = Invoke-ChocoCommand $chocoCommand
  if (-not $isOk) {
    throw $message
  }

  Write-Host "WinRAR installation succeeded"

  foreach ($ext in $DefaultFileExtensions) {
    $assocCommand = "assoc $ext=WinRAR_archive"
    cmd.exe /c $assocCommand

    $ftypeCommand = "ftype WinRAR_archive=""$WinRARPath"" ""%1"""
    cmd.exe /c $ftypeCommand

    Write-Host "Associated '$ext' with WinRAR"
  }
}

Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute
