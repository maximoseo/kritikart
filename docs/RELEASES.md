# KritiKart — Release Log

Every shipped artifact is registered here. This file is the single source of truth
for what was released, when, and its verified hash.

| Version | Date (UTC) | Artifact | sha256 | Notes |
|---|---|---|---|---|
| 0.1.0 | pending | build/kritikart.apk (Android arm64, signed) | pending | First release: 6 racers, 3 laps, Storm Coast, difficulty tiers |

## Format rules

- One row per released artifact (APK / Web deploy).
- sha256 is computed AFTER build verification (`apksigner verify` passes).
- Web deploys register the Vercel deployment URL + build hash of the deployed commit.
