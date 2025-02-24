# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
  Import-Module $_.FullName
}

$DefaultFileExtensions = @(
  '.txt',
  '.log',
  '.json',
  '.xml'
)

$notepadPlusPlusPath = "C:\Program Files\Notepad++\notepad++.exe"

function Get-ModuleName {
  return "Install Notepad++"
}

function Test-Execute {
  if (Test-Path $notepadPlusPlusPath) {
    Write-Host "Notepad++ is already installed"
    return $false
  }

  Write-Host "Notepad++ is not installed"
  return $true
}

function Test-Restart {
  return $false
}

function Execute {
  $chocoCommand = "choco install notepadplusplus -f -y"
  $isOk, $message = Invoke-ChocoCommand $chocoCommand
  if (-not $isOk) {
    throw $message
  }

  Write-Host "Notepad++ installation succeeded"

  foreach ($extension in $DefaultFileExtensions) {
    $assocCommand = "assoc $extension=notepad++_file"
    cmd.exe /c $assocCommand

    $ftypeCommand = "ftype notepad++_file=""$notepadPlusPlusPath"" ""%1"""
    cmd.exe /c $ftypeCommand

    Write-Host "Associated '$extension' with Notepad++"
  }
}

Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute
