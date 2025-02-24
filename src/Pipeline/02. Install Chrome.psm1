# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
	Import-Module $_.FullName
}

function Get-ModuleName {
	return "Install Chrome"
}

function Test-ChromeIsInstalled {
	$paths = @(
		"$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
		"$env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe",
		"$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
	)

	foreach ($path in $paths) {
		if (Test-Path $path) {
			return $true
		}
	}

	return $false
}

function Test-Execute {
	if (Test-ChromeIsInstalled) {
		Write-Line "Chrome is already installed"
		return $false
	}

	Write-Line "Chrome is not installed"
	return $true
}

function Test-Restart {
	return $false
}

function Execute {
	function Import-ChromeTemplate {
		$GooglePath = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Google\Chrome"
		$UserDataPath = Join-Path -Path $GooglePath -ChildPath "User Data"
		$ZipFilePath = Join-Path -Path (Resolve-Path "$PSScriptRoot\..") -ChildPath "Assets\Chrome\User Data.zip"

		# Ensure Chrome is not running
		Get-Process -Name "chrome" -ErrorAction SilentlyContinue | Stop-Process -Force

		# Ensure Google directory exists
		if (-not (Test-Path $GooglePath)) {
			New-Item -Path $GooglePath -ItemType Directory -Force | Out-Null
		}

		# Skip extraction if User Data already exists
		if (Test-Path $UserDataPath) {
			Write-Host "Chrome User Data already exists. Skipping extraction."
			return
		}

		# Extract and deploy
		if (-not (Test-Path $ZipFilePath)) {
			throw "chrome-template.zip not found at $ZipFilePath"
		}

		Expand-Archive -Path $ZipFilePath -DestinationPath $GooglePath -Force
	}

	$chocoCommand = "choco install googlechrome -y -f --ignore-checksums"
	$isOk, $message = Invoke-ChocoCommand $chocoCommand
	if (-not $isOk) {
		throw $message
	}

	Import-ChromeTemplate
	Write-Line "Chrome installation succeeded"
}

Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute
