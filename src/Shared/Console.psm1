function Write-Line {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [ValidateSet("INFO", "WARN", "ERR", "")]
        [string]$Level = ""
    )

    Write-Log -message $Message -level $Level -WithTimestamp $false
}

function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [ValidateSet("INFO", "WARN", "ERR", "")]
        [string]$Level = "",

        [bool]$WithTimestamp = $false
    )

    if ($WithTimestamp) {
        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $Message = "[$timestamp] [$Level] $Message"
    }

    $Level = $Level.ToUpper()
    if ($Level -match "INFO") {
        Write-Host $Message -ForegroundColor Cyan
        return
    }

    if ($Level -match "ERR") {
        Write-Host $Message -ForegroundColor Red -BackgroundColor Black
        return
    }

    if ($Level -match "WARN") {
        Write-Host $Message -ForegroundColor Yellow -BackgroundColor Black
        return
    }

    Write-Host $Message
}

Export-ModuleMember -Function Write-Line, Write-Log