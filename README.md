# OpenClaw WSL2 Skills

This repository stores reusable Codex skills for installing, upgrading, restarting, validating, and repairing OpenClaw on Windows with WSL2.

The current focus is a practical operations skill for a Windows host that runs OpenClaw inside `Ubuntu-24.04` on WSL2.

## What This Repository Solves

OpenClaw works well in WSL2, but the operational flow is different from a plain Linux server or a native desktop install.

In this environment, the recurring realities are:
- the OpenClaw CLI runs inside WSL, not directly in native Windows
- the gateway is usually exposed on `127.0.0.1:18789`
- the dashboard must be opened with a tokenized URL
- upgrades can leave the systemd service pointing at an old entrypoint
- WSL often emits noisy warnings even when the gateway itself is healthy

This repository turns those operational lessons into a reusable Codex skill instead of leaving them as ad hoc troubleshooting notes.

## Repository Goal

The goal is to make the OpenClaw lifecycle on Windows + WSL2 predictable.

That includes:
- first-time install
- upgrade to the latest release
- restart after Windows reboot or sleep
- post-upgrade validation
- gateway repair after failed upgrades
- dashboard access troubleshooting
- recording the real fixes that proved reliable in this environment

## Environment Assumptions

Unless intentionally adapted, this repository assumes:
- Windows host
- WSL2 enabled
- distro name: `Ubuntu-24.04`
- Linux user: `shengz`
- gateway bind: `127.0.0.1`
- gateway port: `18789`
- OpenClaw installed inside WSL

If your setup differs, adjust the script parameters before using them as-is.

## Repository Structure

```text
skills/
  openclaw-wsl2-ops/
    SKILL.md
    agents/
      openai.yaml
    references/
      install-upgrade.md
      troubleshooting.md
    scripts/
      check-openclaw-wsl2.ps1
      repair-openclaw-wsl2.ps1
      upgrade-openclaw-wsl2.ps1
```

## The Stable Operating Flow

This repository standardizes the workflow that proved reliable in practice:
1. Inspect the current state before changing anything.
2. Use the official installer for install or upgrade.
3. After every install or upgrade, run `openclaw gateway install --force`.
4. Restart the gateway.
5. Validate from both WSL and Windows.
6. Open the dashboard only through the tokenized URL from `openclaw dashboard --no-open`.

That sequence avoids most of the failures we repeatedly hit.

## Included Skill

### `openclaw-wsl2-ops`

This skill is built for Codex instances that need to operate OpenClaw in a WSL2-based environment.

It provides:
- a standard install workflow
- a standard upgrade workflow
- a standard restart-after-reboot workflow
- a standard repair workflow
- validation from both WSL and Windows sides
- troubleshooting references for common failures
- PowerShell scripts for check, repair, and upgrade tasks

## What The Skill Contains

### `SKILL.md`

The top-level skill instructions tell Codex:
- when to use the skill
- how to classify the request
- what the default WSL environment looks like
- what the standard install, upgrade, restart, repair, and dashboard flows are

### `references/install-upgrade.md`

This reference now consolidates the core runbook:
- fresh install sequence
- upgrade sequence
- restart-after-reboot sequence
- validation sequence
- why `openclaw gateway install --force` is mandatory in this environment

### `references/troubleshooting.md`

This reference focuses on real failures seen in this environment, including:
- dashboard opens without token and appears broken
- `openclaw update --tag ...` returning `SKIPPED`
- `--install-method git` hanging or partially breaking the CLI
- upgrade succeeded but the gateway service still points to an old path
- installer running `doctor` under `root`
- WSL warning noise that looks serious but often is not fatal

### `scripts/check-openclaw-wsl2.ps1`

This script performs a read-oriented validation pass.

It checks:
- `openclaw --version`
- `openclaw gateway status`
- Windows-side HTTP reachability on `127.0.0.1:18789`
- `openclaw dashboard --no-open`

Use it when you want a fast answer to whether the environment is actually healthy.

### `scripts/repair-openclaw-wsl2.ps1`

This script performs the standard recovery workflow.

It runs:
- `openclaw doctor --fix`
- `openclaw gateway install --force`
- `openclaw gateway restart`
- `openclaw gateway status`
- the final validation script

Use it when the gateway is broken or after an upgrade that completed inconsistently.

### `scripts/upgrade-openclaw-wsl2.ps1`

This script performs the standard upgrade workflow.

It runs:
- current version detection
- npm `latest` detection
- the official installer when an upgrade is needed
- gateway service reinstall
- gateway restart
- final validation

If the installed version already matches npm `latest`, it skips the installer step and still revalidates the environment.

## Quick Start

### 1. Check Current Health

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\openclaw-wsl2-ops\scripts\check-openclaw-wsl2.ps1
```

### 2. Repair A Broken Environment

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\openclaw-wsl2-ops\scripts\repair-openclaw-wsl2.ps1
```

### 3. Upgrade To The Current Latest Release

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\openclaw-wsl2-ops\scripts\upgrade-openclaw-wsl2.ps1
```

## Typical Operating Scenarios

### Fresh Install

The reliable install sequence is:
1. Validate WSL with `wsl --status` and `wsl -l -v`.
2. Enable `systemd` in `/etc/wsl.conf`.
3. Run the official installer.
4. Verify `openclaw --version` as the real Linux user.
5. Configure `~/.openclaw/.env`.
6. Run non-interactive onboarding.
7. Run `openclaw gateway install --force`.
8. Restart the gateway and confirm status.
9. Validate Windows-side access on `127.0.0.1:18789`.
10. Generate the dashboard link with `openclaw dashboard --no-open`.

### Upgrade

The reliable upgrade sequence is:
1. Confirm npm `latest` first.
2. Run the official installer.
3. Run `openclaw gateway install --force`.
4. Restart the gateway.
5. Verify the new version.
6. Confirm Windows-side HTTP returns `200`.
7. Regenerate the tokenized dashboard URL.

This repository treats service reinstall as part of the upgrade, not an optional cleanup step.

### Restart After Windows Reboot Or Sleep

Most common flow:
1. Restart the gateway.
2. Check gateway status.
3. Generate the dashboard URL again.
4. If the page still does not open, check Windows-side `HTTP 200` before assuming the service is down.

### Dashboard Will Not Open

Start by validating the environment:

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\openclaw-wsl2-ops\scripts\check-openclaw-wsl2.ps1
```

If gateway health is good and Windows-side HTTP returns `200`, the gateway is usually fine. In this environment the common cause is opening the bare dashboard URL instead of the tokenized URL returned by `openclaw dashboard --no-open`.

## Which Script To Use

Use `check-openclaw-wsl2.ps1` when:
- you want a quick health check
- you just rebooted Windows
- you just upgraded OpenClaw
- you want to confirm the dashboard link can be generated

Use `repair-openclaw-wsl2.ps1` when:
- gateway status is failing
- the dashboard cannot be opened because the service may be unhealthy
- an upgrade completed but the gateway no longer starts
- you suspect the systemd service path is stale

Use `upgrade-openclaw-wsl2.ps1` when:
- you want to move to the current latest OpenClaw version
- you want the standard upgrade path instead of ad hoc package-manager commands
- you want upgrade plus validation as a single operation

## Why The Workflow Prefers The Official Installer

The official installer proved to be the most reliable path in this environment because it:
- handles package installation consistently
- works for repeated upgrades
- is aligned with the current OpenClaw docs
- avoids some of the ambiguity of direct `openclaw update` on non-git installs

The repository still documents failure modes around the installer, but it remains the default path.

## Why Service Reinstall Is Mandatory After Upgrade

A successful CLI upgrade does not guarantee a healthy gateway service.

A stale systemd service may still point to an old entrypoint such as:
- `~/.npm-global/lib/node_modules/openclaw/dist/index.js`

While the new install may live under:
- `/usr/lib/node_modules/openclaw/dist/index.js`

That is why the standard workflow always includes:

```powershell
openclaw gateway install --force
```

## Known Pitfalls Covered By This Repository

This repository already captures these recurring problems:
- `openclaw update --tag ...` returning `SKIPPED` on non-git installs
- `--install-method git` hanging or leaving the CLI half-installed
- the official installer succeeding but the gateway still referencing an old path
- dashboard access without `#token=...`
- installer output under `root` not matching the real user environment
- WSL NAT and path-translation warnings that are usually non-fatal
- PowerShell and Bash syntax differences during troubleshooting

## Notes About WSL Output Noise

The environment often emits warnings such as:
- `localhost proxy ... NAT mode`
- `Failed to translate 'E:\Program Files\MATLAB\...'`

These warnings matter to recognize, but in most tested cases they were not the root cause of OpenClaw failures. The scripts in this repository intentionally tolerate those messages and continue judging success by exit code and actual health checks.

## Using This Skill With Codex

If you want Codex to use this skill directly, place or install `skills/openclaw-wsl2-ops` into your Codex skills directory, then invoke it as:

```text
$openclaw-wsl2-ops
```

Typical prompts include:
- use `$openclaw-wsl2-ops` to restart my OpenClaw gateway after reboot
- use `$openclaw-wsl2-ops` to upgrade OpenClaw to latest and verify it
- use `$openclaw-wsl2-ops` to repair my WSL2 OpenClaw environment

## Related Files

The operational knowledge in this repository was derived from a working local runbook and then refined through real install and upgrade incidents. Keep the skill, the local runbook, and the GitHub README aligned so the documented workflow does not drift.
