# Troubleshooting

## Gateway Runs In WSL But Browser Cannot Open

Check in this order:

1. `wsl -d Ubuntu-24.04 -u shengz -- openclaw gateway status`
2. `powershell -NoProfile -Command 'try { (Invoke-WebRequest -UseBasicParsing http://127.0.0.1:18789/ -TimeoutSec 5).StatusCode } catch { $_.Exception.Message }'`
3. `wsl -d Ubuntu-24.04 -u shengz -- openclaw dashboard --no-open`

If status is healthy and Windows returns `200`, the issue is usually:
- the user opened `http://127.0.0.1:18789/` without `#token=...`
- the browser tab is stale
- the user opened the link from a different machine instead of the Windows host

## `openclaw update --tag ...` Returns `SKIPPED`

Cause:
- current install is not a git checkout
- OpenClaw cannot safely infer the package manager path

Fix:
- do not force `openclaw update`
- use the official installer instead

## `--install-method git` Gets Stuck

Symptoms:
- install runs for a long time
- `openclaw` temporarily becomes unavailable
- partial files appear under `/usr/lib/node_modules/openclaw`

Practical recovery:
1. inspect whether the package body has actually landed
2. if the installer is clearly stuck, stop the residual install process
3. restore the CLI entrypoint if needed
4. rerun the official installer without `--install-method git`
5. reinstall and restart the gateway service

## Upgrade Finished But Gateway Will Not Start

Typical symptom:
- `openclaw --version` shows the new version
- `openclaw gateway restart` times out
- logs still point at `~/.npm-global/...`

Fast repair:

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\openclaw-wsl2-ops\scripts\repair-openclaw-wsl2.ps1
```

Manual fix:

```powershell
wsl -d Ubuntu-24.04 -u shengz -- bash -lc "openclaw doctor --fix"
wsl -d Ubuntu-24.04 -u shengz -- bash -lc "openclaw gateway install --force && openclaw gateway restart && openclaw gateway status"
```

## Installer Ran Under `root`

The installer may run `doctor` using `/root/.openclaw`, which is not the active user environment for normal operations.

Implication:
- ignore `root`'s missing local state unless the request is explicitly about the `root` user
- validate and repair the `shengz` user environment after install

Use:

```powershell
wsl -d Ubuntu-24.04 -u shengz -- openclaw --version
wsl -d Ubuntu-24.04 -u shengz -- bash -lc "openclaw gateway install --force && openclaw gateway restart && openclaw gateway status"
```

## Noisy WSL Warnings

Usually non-fatal:
- `localhost proxy ... NAT mode`
- `Failed to translate 'E:\Program Files\MATLAB\...'`

Do not treat these as the primary root cause unless evidence points there.

## PowerShell Versus Bash

PowerShell does not support Bash idioms like:
- `|| true`
- `| head -n 20`

When Bash behavior is needed, run:

```powershell
wsl -d Ubuntu-24.04 -u shengz -- bash -lc "command here"
```

## Keep Gateway Alive Across Logout

One-time command:

```powershell
wsl -d Ubuntu-24.04 -u root -- loginctl enable-linger shengz
```

This helps after logout, but not after full Windows shutdown.
