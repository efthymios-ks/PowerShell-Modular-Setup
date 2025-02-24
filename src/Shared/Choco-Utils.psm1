function Invoke-ChocoCommand {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Command
    )

    $errorPatterns = @(
        "not installed",
        "error",
        "exception",
        "fail",
        "not found"
    )

    try {
        Write-Host "Executing: '$Command'"
        $Output = Invoke-Expression -Command "$Command 2>&1"
        $Output = $Output -join "`n"

        foreach ($pattern in $errorPatterns) {
            if ($Output -match "(?i)$pattern") {
                $Output = Get-Failure $Output
                return $false, $Output
            }
        }

        return $true, ""
    }
    catch {
        return $false, $_.Exception.Message
    }
}

function Sync-ChocoEnv {
    param (
        [string]$WithDelay = $true
    )

    if ($WithDelay) {
        Start-Sleep -Seconds 3
    }

    Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
    refreshenv
}

function Get-Failure {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Output
    )

    $lines = $Output -split "`n"
    $failureIndex = -1
    for ($i = 0; $i -lt $lines.Length; $i++) {
        if ($lines[$i] -match '^(failure)') {
            $failureIndex = $i
            break
        }
    }

    if ($failureIndex -ge 0) {
        return $lines[($failureIndex + 1)..($lines.Length - 1)] -join "`n"
    }

    return $Output;
}


Export-ModuleMember -Function Invoke-ChocoCommand, Sync-ChocoEnv