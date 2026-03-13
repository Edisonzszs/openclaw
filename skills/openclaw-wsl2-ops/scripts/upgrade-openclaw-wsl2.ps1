param(
    [string]$Distro = "Ubuntu-24.04",
    [string]$User = "shengz",
    [int]$Port = 18789,
    [switch]$ForceInstall
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

function Invoke-WslCapture {
    param(
        [string]$DistroName,
        [string]$LinuxUser,
        [string]$CommandText
    )

    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & wsl -d $DistroName -u $LinuxUser -- bash -lc $CommandText 2>&1 | ForEach-Object { "$_" }
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorAction
    }

    [pscustomobject]@{
        ExitCode = $code
        Output = Normalize-Output -Lines $output
    }
}

function Invoke-WslStep {
    param(
        [string]$DistroName,
        [string]$LinuxUser,
        [string]$CommandText,
        [string]$StepName
    )

    Write-Host "==> $StepName"
    $result = Invoke-WslCapture -DistroName $DistroName -LinuxUser $LinuxUser -CommandText $CommandText
    if ($result.Output) {
        Write-Host $result.Output
    }
    if ($result.ExitCode -ne 0) {
        throw "Step failed: $StepName"
    }
    $result
}

function Parse-Version {
    param([string]$Text)

    $match = [regex]::Match($Text, '(\d{4}\.\d+\.\d+(?:-[A-Za-z0-9\.\-]+)?)')
    if (-not $match.Success) {
        throw "Unable to parse version from: $Text"
    }
    $match.Groups[1].Value
}

$current = Invoke-WslStep -DistroName $Distro -LinuxUser $User -StepName "current version" -CommandText "openclaw --version"
$currentVersion = Parse-Version -Text $current.Output

$latest = Invoke-WslStep -DistroName $Distro -LinuxUser $User -StepName "npm latest version" -CommandText "npm view openclaw version dist-tags --json"
$latestVersion = if ($latest.Output -match '"version"\s*:\s*"([^"]+)"') { $Matches[1] } else { throw "Unable to parse latest version" }

Write-Host "Current: $currentVersion"
Write-Host "Latest:  $latestVersion"

if ($ForceInstall -or ($currentVersion -ne $latestVersion)) {
    Invoke-WslStep -DistroName $Distro -LinuxUser "root" -StepName "official installer upgrade" -CommandText "curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard --no-gum"
} else {
    Write-Host "==> installer skipped"
    Write-Host "Already at latest version."
}

Invoke-WslStep -DistroName $Distro -LinuxUser $User -StepName "verify version" -CommandText "openclaw --version"
Invoke-WslStep -DistroName $Distro -LinuxUser $User -StepName "gateway install --force" -CommandText "openclaw gateway install --force"
Invoke-WslStep -DistroName $Distro -LinuxUser $User -StepName "gateway restart" -CommandText "openclaw gateway restart"
Invoke-WslStep -DistroName $Distro -LinuxUser $User -StepName "gateway status" -CommandText "openclaw gateway status"

Write-Host "==> final validation"
powershell -ExecutionPolicy Bypass -File "$PSScriptRoot\check-openclaw-wsl2.ps1" -Distro $Distro -User $User -Port $Port
