# KritiKart

A 3D arcade kart-racing game built on **Godot 4.7.2** (Jolt Physics, Forward+ on desktop,
Mobile renderer on Android/Web). Created with Summer Engine's `3d-racing-game` template,
then customized for the KritiKart project.

## Gameplay (v0.1.0)

- 3-lap races, **6 racers** (player + 5 AI opponents with distinct personalities)
- Difficulty tiers (easy / medium / hard) with player assists and rubber-band AI
- Procedural "Storm Coast" circuit: wet asphalt, cliffside jump set-pieces, storm lighting
- Countdown start, checkpoints, wrong-way detection, live position sorting, race results
- Offline-first; optional cloud leaderboards via Supabase (see `docs/SUPABASE.md`)

## Quick start

```bash
# desktop run
godot --path . 

# headless smoke test (no GPU) — expects rc=0, no script errors
godot --headless --path . --quit-after 200
```

## Repository layout

```
project.godot          # project config (name, orientation, renderer overrides)
scenes/                # boot, game, ui, menus
scripts/
  vehicles/            # player + AI drivers, vehicle commands
  race/                # race manager, config, laps, positions, results
  game/                # game session autoload
  ui/                  # HUD, countdown, results
resources/
  profiles/            # storm_coast art / lighting / audio / vfx kits
  tracks/              # track configs + environments
assets/                # meshes, textures, audio
tests/autopilot/       # Summer Engine verification harness
docs/                  # BUILD, RELEASES, SUPABASE, WEB, PRESS-KIT
```

## Docs

- `docs/BUILD.md` — full build pipeline (Android APK, Web export)
- `docs/RELEASES.md` — versioned release log with artifact hashes
- `docs/SUPABASE.md` — leaderboard database schema and policies
- `docs/WEB.md` — Vercel web deployment
- `docs/PRESS-KIT.md` — EPK: factsheet, assets, credits
- `docs/AGENTS-GUIDE.md` — operating rules for AI agents working on this repo
