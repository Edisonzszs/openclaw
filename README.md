# OpenClaw Skills

This repository contains reusable Codex skills for operating OpenClaw.

## Included Skill

### `openclaw-wsl2-ops`

Operate OpenClaw on Windows with WSL2 Ubuntu 24.04.

It covers:
- first-time install
- upgrades to the latest OpenClaw version
- post-reboot restart
- gateway repair and recovery
- dashboard access troubleshooting
- one-command validation and repair scripts
- one-command upgrade to npm latest

## Main Files

- `skills/openclaw-wsl2-ops/SKILL.md`
- `skills/openclaw-wsl2-ops/references/install-upgrade.md`
- `skills/openclaw-wsl2-ops/references/troubleshooting.md`
- `skills/openclaw-wsl2-ops/scripts/check-openclaw-wsl2.ps1`
- `skills/openclaw-wsl2-ops/scripts/repair-openclaw-wsl2.ps1`
- `skills/openclaw-wsl2-ops/scripts/upgrade-openclaw-wsl2.ps1`

## Common Commands

Validate the current OpenClaw environment:

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\openclaw-wsl2-ops\scripts\check-openclaw-wsl2.ps1
```

Repair the gateway environment:

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\openclaw-wsl2-ops\scripts\repair-openclaw-wsl2.ps1
```

Upgrade OpenClaw to the current latest release and revalidate:

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\openclaw-wsl2-ops\scripts\upgrade-openclaw-wsl2.ps1
```
