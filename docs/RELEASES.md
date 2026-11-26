# KritiKart — Release Log

Every shipped artifact is registered here. This file is the single source of truth
for what was released, when, and its verified hash.

| Version | Date (UTC) | Artifact | sha256 | Notes |
|---|---|---|---|---|
| 0.1.0 | 2026-09-17 | builds/kritikart-v0.1.0-android-arm64.apk (Android arm64-v8a, signed) | eef26f87b4e5461cf513a0b91406cb05174e90228e99345bdbb8888056a225bb | First release: 6 racers, 3 laps, Storm Coast, difficulty tiers, Supabase leaderboards (RLS), minSdk 24, INTERNET permission |
| 0.1.1 | 2026-09-17 | builds/kritikart-v0.1.1-android-arm64.apk (Android arm64-v8a, signed) | f26f80378b76a7db91018553fd82fb229b9b4f52e7f7993b9081b0be8113acb0 | Slim build (-41% size): 13 oversized textures downscaled to mobile-native resolution. versionCode 2. Web: https://kritikart.maximo-seo.ai |
| 0.2.0 | 2026-11-20 | builds/kritikart-v0.2.0-android-arm64.apk (Android arm64-v8a, signed) | 0768d5f902fb89083ba5e6254dda935f9e4c6c58f709359d4ecd3918fd87c728 | Slice C: daily/streak/unlocks, safe-area touch, viewport-fit web shell, lifecycle save. versionCode 10. **New release keystore** (old key missing on fleet) — signer `cf0077d88cb34f2369fd5e93e312a951ad5305673d2abdd9a39dee5133985ab4`. Web: https://kritikart.maximo-seo.ai · APK: https://kritikart.maximo-seo.ai/apk/latest.apk |
| 0.3.0 | 2026-11-24 | build/kritikart-v0.3.0-android-arm64.apk (Android arm64-v8a, signed) | 6ded2902064ac08cd7fe82ec2c439c40d4627f727d8cbf6099c6161261d3cd73 | Improvements pass: drift mini-turbo boost + HUD boost meter, respawn fade/sting feedback, coastal backdrop + track dressing enabled, countdown beeps use their own files, 31 oversized textures capped (217MB→130MB), in-app update checker (manifest at /apk/version.json, REQUEST_INSTALL_PACKAGES). versionCode 11. **New release keystore** (previous key not on this host) — signer `c893f5b5792f2ec47ba7fc9fbf0739d4c23d866a519c88a23490feea514d822f`, keystore at `~/.local/share/kritikart-signing/` (outside repo). Note: signer differs from 0.2.0, so existing installs must uninstall once before installing 0.3.0; in-app updates work from 0.3.0 onward. |
| 0.4.0 | 2026-11-25 | build/kritikart-v0.4.0-android-arm64.apk (Android arm64-v8a, .NET/mono, signed) | e5496ee77f562a02694d4724ebb32335938b3eac3040e421ef7fdd5bd087c3e7 | C#/C++-era pass: C# gameplay core (KartGameplayCore owns the drift-boost state machine in the shipped car, GDScript fallback on non-.NET builds), slipstream drafting mechanic, adaptive quality scaler, metallic+clearcoat car paint, 4x anisotropic road filtering, Blender Cycles key art. First .NET Android build (mono export templates) — APK grows to 207MB with the .NET runtime. versionCode 12. Signer `c893f5b5792f2ec47ba7fc9fbf0739d4c23d866a519c88a23490feea514d822f` (same key as 0.3.0, in-app updates from 0.3.0 work). |
| 0.5.0 | 2026-11-26 | build/kritikart-v0.5.0-android-arm64.apk (Android arm64-v8a, .NET/mono, signed) | 1b78227edb859813b4018946e99163af5ce91977acd49f313a22c733b6e26c09 | Higgsfield art pass: generated sunset sky panorama wired into Storm Coast, generated key art as Storm Coast track card in the menu. versionCode 13. Signer c893f5b5 (same key, in-app update from 0.4.0 works). |

## Format rules

- One row per released artifact (APK / Web deploy).
- sha256 is computed AFTER build verification (`apksigner verify` passes).
- Web deploys register the Vercel deployment URL + build hash of the deployed commit.
