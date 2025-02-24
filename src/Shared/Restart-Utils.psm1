function Register-ScriptForRestart {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$AbsoluteScriptPath
    )

    $RegistryPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    Set-ItemProperty -Path $RegistryPath -Name "RestartScript" -Value "powershell.exe -ExecutionPolicy Bypass -File `"$AbsoluteScriptPath`""
}

function Restart-Script {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$AbsoluteScriptPath
    )

    Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$AbsoluteScriptPath`""
    exit
}

function Restart-ComputerWithScript {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$AbsoluteScriptPath
    )

    Register-ScriptForRestart -AbsoluteScriptPath $AbsoluteScriptPath
    Restart-Computer -Force
}

function Test-RestartPending {
    if (Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -EA Ignore) {
        return $true
    }

    if (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA Ignore) {
        return $true
    }

    if (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -EA Ignore) {
        return $true
    }

    if (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\ControlSet001\Session Manager" -Name PendingFileRenameOperations -EA Ignore) {
        return $true
    }

    if (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\ControlSet002\Session Manager" -Name PendingFileRenameOperations -EA Ignore) {
        return $true
    }

    try {
        $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
        $status = $util.DetermineIfRebootPending()
        if (($null -ne $status) -and $status.RebootPending) {
            return $true
        }
    }
    catch {
        return $false
    }
}

Export-ModuleMember -Function Restart-Script,
Restart-Computer,
Restart-ComputerWithScript,
Test-RestartPending