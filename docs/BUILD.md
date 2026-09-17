# Build Pipeline — KritiKart

All commands run from the repo root on the Linux build host.

## Prerequisites (already installed on the build host)

| Tool | Location | Notes |
|---|---|---|
| Godot | `/usr/local/bin/godot` | 4.7.2-stable (headless export works) |
| Export templates | `~/.local/share/godot/export_templates/4.7.2.stable/` | includes `android_release.apk`, web wasm |
| Android SDK | `/opt/android-sdk` | build-tools 34.0.0, platform-34 |
| Java (keytool) | system JDK 17 | keystore creation |
| Release keystore | `/root/.hermes/secure/credentials/kritikart-release.keystore` | 600, pass in `/root/.env.secrets` |

## export_presets.cfg (untracked — regenerate like this)

The preset file is git-ignored because it carries signing material. To rebuild it:

1. Copy a minimal preset with: platform `Android`, `package/unique_name="com.maximoseo.kritikart"`,
   `package/name="KritiKart"`, `version/name=<x.y.z>`, `architectures/arm64-v8a=true`,
   `architectures/armeabi-v7a=false`, `screen/immersive_mode=true`.
2. Set `keystore/release` to the keystore path above, `keystore/release_user="kritikart"`,
   and `keystore/release_password` from `KRITIKART_KEYSTORE_PASS` in `/root/.env.secrets`.
3. Web preset: platform `Web`, `variant/template_release`, export to `build/web/index.html`,
   `variant/thread_support=false` (no COOP/COEP headers needed).

## Android APK

```bash
mkdir -p build
godot --headless --path . --export-release "Android" build/kritikart.apk

# verify signature + identity
/opt/android-sdk/build-tools/34.0.0/apksigner verify --print-certs build/kritikart.apk
/opt/android-sdk/build-tools/34.0.0/aapt dump badging build/kritikart.apk | head -5
sha256sum build/kritikart.apk
```

Record version + sha256 in `docs/RELEASES.md`.

## Web export

```bash
godot --headless --path . --export-release "Web" build/web/index.html
ls -la build/web/   # index.html, index.js, index.wasm
```

Deploy: see `docs/WEB.md` (Vercel static + subdomain).

## Smoke test before every build

```bash
godot --headless --path . --quit-after 200   # rc=0, no script errors
```
