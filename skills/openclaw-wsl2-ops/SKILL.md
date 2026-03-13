---
name: openclaw-wsl2-ops
description: Install, upgrade, restart, validate, and repair OpenClaw on Windows with WSL2 Ubuntu 24.04. Use when Codex needs to operate an OpenClaw deployment that runs in WSL, including first-time setup, post-reboot restart, version upgrades, gateway recovery, dashboard access, and troubleshooting issues such as stale systemd service paths, token-missing dashboard access, or installer failures.
---

# OpenClaw WSL2 Ops

Use this skill for the repository's Windows + WSL2 OpenClaw environment.

Assume this default target unless local evidence says otherwise:
- WSL distro: `Ubuntu-24.04`
- Linux user: `shengz`
- Gateway bind: `127.0.0.1`
- Gateway port: `18789`

## Workflow

1. Inspect current state before making changes.
2. Choose the smallest operation that resolves the request.
3. After any install or upgrade, reinstall the gateway service and verify from both WSL and Windows.
4. Prefer the official installer over ad hoc npm or git flows unless there is a specific reason not to.

## Inspect First

Start with:
- `wsl -d Ubuntu-24.04 -u shengz -- openclaw --version`
- `wsl -d Ubuntu-24.04 -u shengz -- openclaw gateway status`
- `powershell -NoProfile -Command 'try { (Invoke-WebRequest -UseBasicParsing http://127.0.0.1:18789/ -TimeoutSec 5).StatusCode } catch { $_.Exception.Message }'`

Use the results to decide whether the task is:
- install/bootstrap
- restart only
- upgrade
- gateway repair
- browser access troubleshooting

## Standard Actions

### Install or Upgrade

Use the official installer:

```powershell
wsl -d Ubuntu-24.04 -u root -- bash -lc "curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard --no-gum"
```

Then always run:

```powershell
wsl -d Ubuntu-24.04 -u shengz -- bash -lc "openclaw gateway install --force && openclaw gateway restart && openclaw gateway status"
```

If the user asked for `latest`, confirm the current npm `latest` first:
- `wsl -d Ubuntu-24.04 -u shengz -- bash -lc "npm view openclaw version dist-tags --json"`

Read [references/install-upgrade.md](references/install-upgrade.md) when performing install or upgrade work.

For repeatable post-upgrade validation, run:
- `powershell -ExecutionPolicy Bypass -File .\skills\openclaw-wsl2-ops\scripts\check-openclaw-wsl2.ps1`

For one-command upgrade to the current latest release, run:
- `powershell -ExecutionPolicy Bypass -File .\skills\openclaw-wsl2-ops\scripts\upgrade-openclaw-wsl2.ps1`

### Restart After Reboot

Use:

```powershell
wsl -d Ubuntu-24.04 -u shengz -- bash -lc "openclaw gateway restart && openclaw gateway status"
wsl -d Ubuntu-24.04 -u shengz -- openclaw dashboard --no-open
```

If the dashboard still seems unreachable, verify Windows-side access before assuming the gateway is down.

### Repair a Broken Gateway

When `openclaw --version` works but the gateway does not start, first suspect service drift after upgrade.

Fast path:

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\openclaw-wsl2-ops\scripts\repair-openclaw-wsl2.ps1
```

Manual path:

```powershell
wsl -d Ubuntu-24.04 -u shengz -- bash -lc "openclaw doctor --fix"
wsl -d Ubuntu-24.04 -u shengz -- bash -lc "openclaw gateway install --force && openclaw gateway restart && openclaw gateway status"
```

If that fails, inspect logs:
- `wsl -d Ubuntu-24.04 -u shengz -- bash -lc "journalctl --user -u openclaw-gateway.service -n 120 --no-pager"`

Read [references/troubleshooting.md](references/troubleshooting.md) for known failures and fixes.

## Dashboard Access

Never send the bare dashboard URL as the primary link. Prefer:

```powershell
wsl -d Ubuntu-24.04 -u shengz -- openclaw dashboard --no-open
```

Use the printed `http://127.0.0.1:18789/#token=...` URL.

If the user says `cannot open`:
- confirm gateway status in WSL
- confirm Windows-side `127.0.0.1:18789` returns `200`
- regenerate the tokenized URL
- only then move on to browser-side troubleshooting

## Environment Notes

- `localhost proxy ... NAT mode` warnings from WSL are usually noise.
- `Failed to translate 'E:\Program Files\MATLAB\...'` warnings are also usually noise.
- PowerShell is not Bash; if Bash syntax is required, wrap with `bash -lc`.
- `loginctl enable-linger shengz` is useful so user services survive logout, but not full Windows shutdown.

## References

- Install, upgrade, and post-upgrade validation: [references/install-upgrade.md](references/install-upgrade.md)
- Troubleshooting and known pitfalls: [references/troubleshooting.md](references/troubleshooting.md)
- Validation script: [scripts/check-openclaw-wsl2.ps1](scripts/check-openclaw-wsl2.ps1)
- Repair script: [scripts/repair-openclaw-wsl2.ps1](scripts/repair-openclaw-wsl2.ps1)
- Upgrade script: [scripts/upgrade-openclaw-wsl2.ps1](scripts/upgrade-openclaw-wsl2.ps1)
