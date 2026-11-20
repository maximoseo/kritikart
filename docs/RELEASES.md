# KritiKart — Release Log

Every shipped artifact is registered here. This file is the single source of truth
for what was released, when, and its verified hash.

| Version | Date (UTC) | Artifact | sha256 | Notes |
|---|---|---|---|---|
| 0.1.0 | 2026-09-17 | builds/kritikart-v0.1.0-android-arm64.apk (Android arm64-v8a, signed) | eef26f87b4e5461cf513a0b91406cb05174e90228e99345bdbb8888056a225bb | First release: 6 racers, 3 laps, Storm Coast, difficulty tiers, Supabase leaderboards (RLS), minSdk 24, INTERNET permission |
| 0.1.1 | 2026-09-17 | builds/kritikart-v0.1.1-android-arm64.apk (Android arm64-v8a, signed) | f26f80378b76a7db91018553fd82fb229b9b4f52e7f7993b9081b0be8113acb0 | Slim build (-41% size): 13 oversized textures downscaled to mobile-native resolution. versionCode 2. Web: https://kritikart.maximo-seo.ai |
| 0.2.0 | 2026-11-20 | builds/kritikart-v0.2.0-android-arm64.apk (Android arm64-v8a, signed) | 0768d5f902fb89083ba5e6254dda935f9e4c6c58f709359d4ecd3918fd87c728 | Slice C: daily/streak/unlocks, safe-area touch, viewport-fit web shell, lifecycle save. versionCode 10. **New release keystore** (old key missing on fleet) — signer `cf0077d88cb34f2369fd5e93e312a951ad5305673d2abdd9a39dee5133985ab4`. Web: https://kritikart.maximo-seo.ai · APK: https://kritikart.maximo-seo.ai/apk/latest.apk |

## Format rules

- One row per released artifact (APK / Web deploy).
- sha256 is computed AFTER build verification (`apksigner verify` passes).
- Web deploys register the Vercel deployment URL + build hash of the deployed commit.
