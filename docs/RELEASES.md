# KritiKart — Release Log

Every shipped artifact is registered here. This file is the single source of truth
for what was released, when, and its verified hash.

| Version | Date (UTC) | Artifact | sha256 | Notes |
|---|---|---|---|---|
| 0.1.0 | 2026-09-17 | builds/kritikart-v0.1.0-android-arm64.apk (Android arm64-v8a, signed) | eef26f87b4e5461cf513a0b91406cb05174e90228e99345bdbb8888056a225bb | First release: 6 racers, 3 laps, Storm Coast, difficulty tiers, Supabase leaderboards (RLS), minSdk 24, INTERNET permission |

## Format rules

- One row per released artifact (APK / Web deploy).
- sha256 is computed AFTER build verification (`apksigner verify` passes).
- Web deploys register the Vercel deployment URL + build hash of the deployed commit.
