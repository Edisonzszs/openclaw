param(
    [string]$Distro = "Ubuntu-24.04",
    [string]$User = "shengz",
    [int]$Port = 18789
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

function Test-HttpStatus {
    param([int]$GatewayPort)

    try {
        $status = (Invoke-WebRequest -UseBasicParsing "http://127.0.0.1:$GatewayPort/" -TimeoutSec 5).StatusCode
        [pscustomobject]@{
            Ok = $true
            Detail = "$status"
        }
    } catch {
        [pscustomobject]@{
            Ok = $false
            Detail = $_.Exception.Message
        }
    }
}

$checks = @()

$version = Invoke-WslCapture -DistroName $Distro -LinuxUser $User -CommandText "openclaw --version"
$checks += [pscustomobject]@{
    Name = "cli_version"
    Ok = ($version.ExitCode -eq 0)
    Detail = if ($version.Output) { $version.Output } else { "openclaw --version failed" }
}

$status = Invoke-WslCapture -DistroName $Distro -LinuxUser $User -CommandText "openclaw gateway status"
$statusOk = ($status.ExitCode -eq 0) -and ($status.Output -match "RPC probe: ok") -and ($status.Output -match "Runtime: running")
$checks += [pscustomobject]@{
    Name = "gateway_status"
    Ok = $statusOk
    Detail = if ($status.Output) { $status.Output } else { "openclaw gateway status failed" }
}

$http = Test-HttpStatus -GatewayPort $Port
$checks += [pscustomobject]@{
    Name = "windows_http"
    Ok = $http.Ok
    Detail = $http.Detail
}

$dashboard = Invoke-WslCapture -DistroName $Distro -LinuxUser $User -CommandText "openclaw dashboard --no-open"
$dashboardUrl = ""
if ($dashboard.Output -match "Dashboard URL:\s*(\S+)") {
    $dashboardUrl = $Matches[1]
}
$checks += [pscustomobject]@{
    Name = "dashboard_url"
    Ok = ($dashboard.ExitCode -eq 0) -and [bool]$dashboardUrl
    Detail = if ($dashboardUrl) { $dashboardUrl } else { $dashboard.Output }
}

$summary = [pscustomobject]@{
    distro = $Distro
    user = $User
    port = $Port
    ok = -not ($checks.Ok -contains $false)
    checks = $checks
}

$summary | ConvertTo-Json -Depth 4

if (-not $summary.ok) {
    exit 1
}
