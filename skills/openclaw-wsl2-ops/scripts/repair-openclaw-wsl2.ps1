param(
    [string]$Distro = "Ubuntu-24.04",
    [string]$User = "shengz",
    [int]$Port = 18789,
    [switch]$SkipDoctor
)

$ErrorActionPreference = "Stop"

function Normalize-Output {
    param([string[]]$Lines)

    $text = ($Lines -join "`n").Trim()
    $text = ($text -split "`r?`n") | Where-Object {
        $_ -and
        $_ -notmatch "localhost.*WSL.*NAT" -and
        $_ -notmatch "Failed to translate" -and
        $_ -notmatch "your 131072x1 screen size is bogus"
    }
    ($text -join "`n").Trim()
}

function Invoke-WslStep {
    param(
        [string]$DistroName,
        [string]$LinuxUser,
        [string]$CommandText,
        [string]$StepName
    )

    Write-Host "==> $StepName"
    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & wsl -d $DistroName -u $LinuxUser -- bash -lc $CommandText 2>&1 | ForEach-Object { "$_" }
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorAction
    }

    $filtered = Normalize-Output -Lines $output
    if ($filtered) {
        Write-Host $filtered
    }

    if ($code -ne 0) {
        throw "Step failed: $StepName"
    }
}

if (-not $SkipDoctor) {
    Invoke-WslStep -DistroName $Distro -LinuxUser $User -StepName "openclaw doctor --fix" -CommandText "openclaw doctor --fix"
}

Invoke-WslStep -DistroName $Distro -LinuxUser $User -StepName "openclaw gateway install --force" -CommandText "openclaw gateway install --force"
Invoke-WslStep -DistroName $Distro -LinuxUser $User -StepName "openclaw gateway restart" -CommandText "openclaw gateway restart"
Invoke-WslStep -DistroName $Distro -LinuxUser $User -StepName "openclaw gateway status" -CommandText "openclaw gateway status"

Write-Host "==> final validation"
powershell -ExecutionPolicy Bypass -File "$PSScriptRoot\check-openclaw-wsl2.ps1" -Distro $Distro -User $User -Port $Port
