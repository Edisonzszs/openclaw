# Install And Upgrade

## Defaults For This Environment

- Windows host runs WSL2
- Distro: `Ubuntu-24.04`
- Linux user: `shengz`
- OpenClaw gateway port: `18789`
- Gateway bind: `loopback`

## Fresh Install

1. Validate WSL:
   - `wsl --status`
   - `wsl -l -v`
2. If needed, install distro with the repo helper:
   - `.\deploy-wsl2.ps1`
3. Ensure `systemd` is enabled in `/etc/wsl.conf`
4. Shut down WSL:
   - `wsl --shutdown`
5. Install OpenClaw:

```powershell
wsl -d Ubuntu-24.04 -u root -- bash -lc "curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard --no-gum"
```

6. Verify CLI:
   - `wsl -d Ubuntu-24.04 -u shengz -- openclaw --version`
7. Configure `~/.openclaw/.env` with provider credentials
8. Run non-interactive onboarding
9. Reinstall gateway service once:

```powershell
wsl -d Ubuntu-24.04 -u shengz -- bash -lc "openclaw gateway install --force && openclaw gateway restart && openclaw gateway status"
```

## Upgrade

Preferred upgrade path:

```powershell
wsl -d Ubuntu-24.04 -u root -- bash -lc "curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard --no-gum"
```

Then always run:

```powershell
wsl -d Ubuntu-24.04 -u shengz -- openclaw --version
wsl -d Ubuntu-24.04 -u shengz -- bash -lc "openclaw gateway install --force && openclaw gateway restart && openclaw gateway status"
```

## Post-Upgrade Validation

Run all of these:

```powershell
wsl -d Ubuntu-24.04 -u shengz -- openclaw --version
wsl -d Ubuntu-24.04 -u shengz -- openclaw gateway status
powershell -NoProfile -Command 'try { (Invoke-WebRequest -UseBasicParsing http://127.0.0.1:18789/ -TimeoutSec 5).StatusCode } catch { $_.Exception.Message }'
wsl -d Ubuntu-24.04 -u shengz -- openclaw dashboard --no-open
```

Expected outcome:
- CLI reports the new version
- gateway status reports `running`
- Windows-side HTTP returns `200`
- dashboard command returns a tokenized URL

For one-command validation, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\openclaw-wsl2-ops\scripts\check-openclaw-wsl2.ps1
```

For one-command upgrade to npm latest, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\openclaw-wsl2-ops\scripts\upgrade-openclaw-wsl2.ps1
```

## Why Reinstall The Service Every Time

Older installs can leave the systemd service pointing at an outdated entrypoint such as:
- `~/.npm-global/lib/node_modules/openclaw/dist/index.js`

Newer installs may live under:
- `/usr/lib/node_modules/openclaw/dist/index.js`

If the service file is stale, the CLI can show the new version while the gateway still fails to start.
