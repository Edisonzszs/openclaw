# OpenClaw WSL2 Skills

This repository stores reusable Codex skills for installing, upgrading, restarting, validating, and repairing OpenClaw on Windows with WSL2.

The current focus is a production-style operations skill for a Windows host that runs OpenClaw inside `Ubuntu-24.04` on WSL2.

## Background

Running OpenClaw on Windows through WSL2 works well, but the operating workflow is different from a plain Linux server or a local macOS install.

In practice, this environment has a few repeatable characteristics:
- the OpenClaw CLI runs inside WSL, not directly in native Windows
- the gateway is usually bound to `127.0.0.1:18789`
- the dashboard must be opened with a tokenized URL
- upgrades can leave the systemd service pointing at an old entrypoint
- noisy WSL warnings often appear even when the gateway is healthy

This repository captures those operational details as a Codex skill so the workflow is reusable instead of being re-derived every time.

## Repository Goal

The goal of this repository is to make OpenClaw lifecycle management on Windows + WSL2 predictable.

That includes:
- first-time install
- upgrade to the latest release
- restart after Windows reboot
- health validation
- gateway repair after failed upgrades
- dashboard access troubleshooting
- codifying the real fixes that were needed in this environment

## Included Skill

### `openclaw-wsl2-ops`

This skill is built for Codex instances that need to operate OpenClaw in a WSL2-based environment.

It provides:
- a workflow for inspecting the current state before acting
- a standard upgrade path using the official installer
- a standard repair path using `doctor --fix` and service reinstall
- a standard validation path from both WSL and Windows sides
- references for troubleshooting common failures
- PowerShell automation scripts for check, repair, and upgrade tasks

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

## Environment Assumptions

Unless intentionally adapted, this repository assumes the following environment:
- Windows host
- WSL2 enabled
- distro name: `Ubuntu-24.04`
- Linux user: `shengz`
- gateway bind: `loopback`
- gateway port: `18789`
- OpenClaw installed inside WSL

If your local setup differs, adjust the script parameters before using them as-is.

## What The Skill Contains

### `SKILL.md`

The top-level skill instructions tell Codex:
- when to use the skill
- how to classify a request
- what the default WSL environment looks like
- what the standard install, upgrade, restart, repair, and dashboard flows are

### `references/install-upgrade.md`

This reference focuses on:
- fresh install sequence
- upgrade sequence
- post-upgrade validation sequence
- why `openclaw gateway install --force` is always part of the workflow

### `references/troubleshooting.md`

This reference focuses on real failures that happened in this environment, including:
- dashboard opens without token and appears broken
- `openclaw update --tag ...` returning `SKIPPED`
- `--install-method git` hanging or partially breaking the CLI
- upgrade succeeded but gateway service still points to an old path
- installer running `doctor` under `root`
- WSL warning noise that looks scary but is often not fatal

### `scripts/check-openclaw-wsl2.ps1`

This script performs a read-oriented validation pass.

It checks:
- `openclaw --version`
- `openclaw gateway status`
- Windows-side HTTP reachability on `127.0.0.1:18789`
- `openclaw dashboard --no-open`

It returns structured JSON so the result is easy to inspect or automate around.

### `scripts/repair-openclaw-wsl2.ps1`

This script performs the standard recovery workflow.

It runs:
- `openclaw doctor --fix`
- `openclaw gateway install --force`
- `openclaw gateway restart`
- `openclaw gateway status`
- the final validation script

Use this when the gateway is broken or after a failed or inconsistent upgrade.

### `scripts/upgrade-openclaw-wsl2.ps1`

This script performs the standard upgrade workflow.

It runs:
- current version detection
- npm `latest` detection
- official installer when an upgrade is needed
- gateway service reinstall
- gateway restart
- final validation

If the installed version already matches npm `latest`, it skips the installer step and still revalidates the environment.

## Quick Start

### Validate the current environment

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\openclaw-wsl2-ops\scripts\check-openclaw-wsl2.ps1
```

### Repair a broken environment

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\openclaw-wsl2-ops\scripts\repair-openclaw-wsl2.ps1
```

### Upgrade to the current latest release

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\openclaw-wsl2-ops\scripts\upgrade-openclaw-wsl2.ps1
```

## Which Script To Use

Use `check-openclaw-wsl2.ps1` when:
- you want a fast health check
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
- you want a safe standard upgrade path instead of ad hoc package-manager commands
- you want upgrade plus validation as a single operation

## Typical Operating Flows

### 1. After Windows Reboot

Most common workflow:

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\openclaw-wsl2-ops\scripts\check-openclaw-wsl2.ps1
```

If the gateway is not healthy:

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\openclaw-wsl2-ops\scripts\repair-openclaw-wsl2.ps1
```

### 2. Before Or After Upgrade

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\openclaw-wsl2-ops\scripts\upgrade-openclaw-wsl2.ps1
```

This covers:
- version comparison
- official installer execution when needed
- service reinstall
- gateway restart
- final verification

### 3. Dashboard Will Not Open

First validate the environment:

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\openclaw-wsl2-ops\scripts\check-openclaw-wsl2.ps1
```

If gateway health is good and Windows-side HTTP returns `200`, the most likely problem is not the gateway itself. In this environment the usual cause is opening the bare dashboard URL instead of the tokenized URL returned by `openclaw dashboard --no-open`.

### 4. Upgrade Succeeded But Gateway Failed

This repository treats this as a first-class failure mode.

The expected recovery is:
- reinstall the gateway service
- restart it
- validate again

In practice, this is usually caused by the service file still pointing at an old OpenClaw installation path.

## Known Pitfalls Covered By This Repository

This repository already captures these recurring problems:
- `openclaw update --tag ...` returning `SKIPPED` on non-git installs
- `--install-method git` hanging or leaving the CLI half-installed
- the official installer succeeding but the gateway still referencing an old path
- dashboard access without `#token=...`
- installer output under `root` not matching the real user environment
- WSL NAT and path-translation warnings that are usually non-fatal
- PowerShell and Bash syntax differences during troubleshooting

## Why The Workflow Prefers The Official Installer

The official installer proved to be the most reliable path in this environment because it:
- handles package installation consistently
- works for repeated upgrades
- is aligned with current OpenClaw docs
- avoids some of the ambiguity of direct `openclaw update` on non-git installs

The repository still documents failure modes around the installer, but it remains the standard path.

## Why Service Reinstall Is Mandatory After Upgrade

A key lesson in this environment is that a successful CLI upgrade does not guarantee a healthy gateway service.

A stale systemd service may still point to an old entrypoint such as:
- `~/.npm-global/lib/node_modules/openclaw/dist/index.js`

While the new install may live under:
- `/usr/lib/node_modules/openclaw/dist/index.js`

That is why the standard workflow always includes:

```powershell
openclaw gateway install --force
```

## Notes About WSL Output Noise

The environment often emits warnings such as:
- `localhost proxy ... NAT mode`
- `Failed to translate 'E:\Program Files\MATLAB\...'`

These warnings are important to recognize, but in most of the tested cases they were not the root cause of OpenClaw failures. The scripts in this repository intentionally tolerate those messages and continue judging success by exit code and actual health checks.

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

The operational knowledge in this repository was derived from a working local runbook and iteratively refined through real install and upgrade incidents. If you maintain a separate local operations repo, keep the two in sync so the skill and the manual runbook do not drift apart.
