# Import shared modules
$sharedModulesPath = Join-Path $PSScriptRoot "Shared"
Get-ChildItem -Path $sharedModulesPath -Filter "*.psm1" | ForEach-Object {
    Import-Module $_.FullName
}

$absoluteScriptPath = $MyInvocation.MyCommand.Path
$restartDelaySeconds = 5
# If not running as Administrator, relaunch with Administrator privileges
if (-not (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Line "This script requires elevated permissions. Restarting with administrator privileges" "WARN"
    Start-Sleep -Seconds $restartDelaySeconds
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $PSCommandPath -NoExit" -Verb RunAs
    EXIT
}

# Get all modules
$modulesPath = Join-Path $PSScriptRoot "Pipeline"
$moduleFiles = Get-ChildItem -Path $modulesPath -Filter "*.psm1"
$moduleFiles = $moduleFiles | Sort-Object {
    # 1. File1.psm1
    # 2. File2.psm1
    # etc...
    if ($_ -match '^\d+(?=\.)') {
        return [int]$matches[0]
    }

    return 0
}

# Start logging to the file
$logFileName = "log-" + (Get-Date -Format "yyyy-MM-dd_HH-mm-ss-fff") + ".log"
$logFilePath = Join-Path $PSScriptRoot "Logs/$logFileName"
Start-Transcript -Path $logFilePath

try {
    # Check if no modules are found
    if ($moduleFiles.Count -eq 0) {
        Write-Line "No module scripts found in '$modulesPath'. Exiting" "ERR"
        return
    }

    # Loop through each module script
    $totalModules = $moduleFiles.Count
    $index = 1
    foreach ($moduleFile in $moduleFiles) {
        # Check if reboot is pending
        if (Test-RestartPending) {
            Write-Line "Pending reboot detected. Restarting" "WARN"
            Start-Sleep -Seconds $restartDelaySeconds
            Restart-ComputerWithScript -AbsoluteScriptPath $absoluteScriptPath
            exit
        }

        # Import the module
        Import-Module $moduleFile.FullName

        $lineSeparator = "####################################################################"
        $moduleName = Get-ModuleName -moduleFilePath $moduleFile.FullName

        Write-Line $lineSeparator "INFO"
        Write-Line "[$index/$totalModules] Module: ${moduleName}" "INFO"
        Write-Line "Loaded module" "INFO"

        try {
            # Test-Execute
            if (-not(Test-Execute)) {
                Write-Line "Skipping execution" "INFO"
                continue
            }

            # Execute
            Execute
            Write-Line "Execution succeeded" "INFO"

            # Test-Restart
            if (Test-Restart) {
                Write-Line "Reboot requested. Restarting" "WARN"
                Start-Sleep -Seconds $restartDelaySeconds
                Restart-ComputerWithScript -AbsoluteScriptPath $absoluteScriptPath
                exit
            }
        }
        catch {
            # Check if reboot is pending
            $regexRestartPatterns = @(
                "pending.*reboot.*detected",
                "reboot.*required"
            )

            if ($_ -match "(?i)($($regexRestartPatterns -join '|'))") {
                Write-Line "Pending reboot detected. Restarting" "WARN"
                Start-Sleep -Seconds $restartDelaySeconds
                Restart-ComputerWithScript -AbsoluteScriptPath $absoluteScriptPath
                exit
            }

            # Else break
            Write-Line "Execution failed: $_" "ERR"
            break
        }
        finally {
            Write-Line $lineSeparator "INFO"
            Write-Host ""
            $index++
        }
    }

    Write-Line "Finished setup" "INFO"
}
finally {
    Stop-Transcript
}

Read-Host