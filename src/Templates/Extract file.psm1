# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
  Import-Module $_.FullName
}

<#
  Destination folder is not completely overriden.
  It adds or updates items from source folder.
  It does not delete items from destination folder.
#>

$ZipFilePath = 'C:\Users\Makis-VM\Desktop\User Data.zip';
$DestinationPath = 'C:\Users\Makis-VM\Desktop\Results';

function Get-ModuleName {
  return "Extract file"
}

function Test-Execute {
  if (-Not (Test-Path $ZipFilePath -PathType Leaf)) {
    Write-Host "'$ZipFilePath' not found"
    return $false
  }

  Write-Host "Extracting '$ZipFilePath' to '$DestinationPath'"
  return $true
}

function Test-Restart {
  return $false
}

function Execute {
  # Ensure destination folder exists
  if (-Not (Test-Path $DestinationPath -PathType Container)) {
    Write-Host "Destination folder '$extractPath' does not exist. Creating it..."
    New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
  }

  # Load the required assembly if not already loaded
  Add-Type -AssemblyName System.IO.Compression.FileSystem

  $zip = $null
  try {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($ZipFilePath)

    foreach ($entry in $zip.Entries) {
      $destination = Join-Path -Path $DestinationPath -ChildPath $entry.FullName
      $destinationFolder = Split-Path -Path $destination -Parent

      # Folder
      if (-Not $entry.Name) {
        if (-Not (Test-Path $destinationFolder -PathType Container)) {
          Write-Host "Creating folder: '$destinationFolder'"
          New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null
        }

        continue
      }

      # File
      if (Test-Path $destination -PathType Leaf) {
        Write-Host "Overriding file: '$destination'"
      }
      else {
        New-Item -ItemType File -Path $destination -Force | Out-Null
        Write-Host "Extracting new file: '$destination'"
      }

      $entryStream = $null
      $fileStream = $null

      try {
        $entryStream = $entry.Open()
        $fileStream = [System.IO.File]::Open($destination, "Create", "Write", "ReadWrite")
        $entryStream.CopyTo($fileStream)
      }
      finally {
        if ($entryStream) {
          $entryStream.Close()
        }
        if ($fileStream) {
          $fileStream.Close()
        }
      }
    }
  }
  finally {
    if ($zip) {
      $zip.Dispose()
    }
  }

  Write-Host "Extraction completed"
}

Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute