# Agent Guide — operating rules for AI bots on this repo

Any bot (Claude, Codex, Hermes, Summer, human) touching this repository follows these rules.
(This file is the agent guide; kept under docs/ so it travels with the repo.)

## Identity

- Project: **KritiKart** — 3D kart racer, Godot 4.7.2-stable
- Owner: Tomerake / MaximoSEO
- Build host: `/root/projects/kritikart` (Linux)

## Golden rules

1. **Never commit secrets.** Keystore password, API keys and tokens live OUTSIDE the repo:
   - `/root/.env.secrets` (600) — `KRITIKART_KEYSTORE_PASS`, `SUPABASE_*`, etc.
   - Doppler project `agents` config `prd` — `GH_TOKEN`, `SUMMER_AUTH_TOKEN`
   - Keystore: `/root/.hermes/secure/credentials/kritikart-release.keystore` (600)
   - `.gitignore` already excludes `export_presets.cfg`, `*.keystore`, `.env*` — keep it that way.
2. **Verify, never assume.** After any change:
   - Headless smoke: `godot --headless --path . --quit-after 200` → rc=0, no script errors.
   - Builds: verify APK with `apksigner verify` + `aapt dump badging`; web build loads.
3. **Register every release** in `docs/RELEASES.md` (version, date, sha256, changes) —
   the release log is the single source of truth for "what shipped".
4. **One engine version.** Godot 4.7.2-stable at `/usr/local/bin/godot`; export templates at
   `~/.local/share/godot/export_templates/4.7.2.stable/`. Do not mix versions.
5. **Offline-first gameplay.** Network features (leaderboards) must degrade gracefully —
   never block gameplay on connectivity.

## Commands cheatsheet

```bash
# smoke test
godot --headless --path . --quit-after 200

# Android release APK (signed) → build/kritikart.apk
godot --headless --path . --export-release "Android" build/kritikart.apk

# Web export → build/web/
godot --headless --path . --export-release "Web" build/web/index.html

# verify APK
/opt/android-sdk/build-tools/34.0.0/apksigner verify --print-certs build/kritikart.apk
/opt/android-sdk/build-tools/34.0.0/aapt dump badging build/kritikart.apk | head -5
sha256sum build/kritikart.apk
```

## Where things are

- Race rules: `scripts/race/race_config.gd` (laps=3, npc_count=5, difficulty tiers)
- Track/theme kits: `resources/profiles/storm_coast_*.tres`
- Export presets: `export_presets.cfg` (untracked; regenerate per `docs/BUILD.md`)
- Summer Engine verify harness: `tests/autopilot/run.sh`
- Supabase leaderboards: `docs/SUPABASE.md`
