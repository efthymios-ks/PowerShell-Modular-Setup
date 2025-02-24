# Import shared modules
$sharedModulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
	Import-Module $_.FullName
}

$HostsFilePath = "C:\Windows\System32\drivers\etc\hosts"
$HostEntries = @(
	"127.0.0.1 example1.local",
	"127.0.0.1 example2.local",
	"127.0.0.1 example3.local"
)

function Get-ModuleName {
	return "Edit hosts"
}

function Test-Execute {
	return $true
}

function Test-Restart {
	return $false
}

function Execute {
	$hostsContent = Get-Content $HostsFilePath

	$entriesToAdd = $HostEntries |
	ForEach-Object { $_.Trim() } |
	Select-Object -Unique |
	Sort-Object

	# Remove entries if exist, to group and re-add them at the end
	$hostsContent = $hostsContent | Where-Object {
		$line = $_.Trim()
		-not ($entriesToAdd | Where-Object { $line -contains $_ })
	}

	$finalContent = $hostsContent + "`n" + $entriesToAdd
	$finalContent | Set-Content $HostsFilePath

	Write-Line "Hosts file has been updated `nCheck at '$HostsFilePath'"
}

Export-ModuleMember -Function Get-ModuleName, Test-Execute, Test-Restart, Execute