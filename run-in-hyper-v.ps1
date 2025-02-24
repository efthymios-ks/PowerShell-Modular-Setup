$vmName = "Windows 10 VM"
$username = "MAKIS-VM"
$password = "1234"

$sourceFolder = "$PSScriptRoot\src"
$destinationRoot = "C:\Users\Public\Desktop\src"

# Convert password to secure string and create credential
$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username, $securePassword)

# Delete the destination folder on the VM if it exists
Invoke-Command -VMName $vmName -ScriptBlock {
  param($destinationRoot)

  if (Test-Path -Path $destinationRoot) {
    Remove-Item -Path $destinationRoot -Recurse -Force
  }

} -ArgumentList $destinationRoot -Credential $credential

# Copy files from source to VM
$files = Get-ChildItem -Path $sourceFolder -File -Recurse
foreach ($file in $files) {
  $relativePath = $file.FullName.Substring($sourceFolder.Length).TrimStart("\")
  $destinationPath = Join-Path -Path $destinationRoot -ChildPath $relativePath

  Copy-VMFile -Name $vmName -SourcePath $file.FullName -DestinationPath $destinationPath -FileSource Host -CreateFullPath -Force
}

# Run script on the VM
$scriptPath = Join-Path -Path $destinationRoot -ChildPath "Run.ps1"
Invoke-Command -VMName $vmName -ScriptBlock {
  param($scriptPath)
  Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

  if (Test-Path -Path $scriptPath) {
    Invoke-Expression -Command "& $scriptPath"
  }

} -ArgumentList $scriptPath -Credential $credential
