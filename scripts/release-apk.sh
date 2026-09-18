#!/usr/bin/env bash
# KritiKart release: keep ONLY the newest APK at srv1331236.hstgr.cloud (apk-dl container
# bind-mounts this builds/ dir). Deletes every older APK/idsig/parts, updates dl.html
# (FILE, SHA, title, badge), regenerates 44MB chat-delivery parts.
# Usage: scripts/release-apk.sh [path/to/new.apk]   (default: newest kritikart-v*.apk here)
set -euo pipefail
cd "$(dirname "$0")/../builds"

APK="${1:-$(ls -t kritikart-v*-android-arm64.apk 2>/dev/null | head -1)}"
[ -f "$APK" ] || { echo "ERROR: APK not found: $APK"; exit 1; }
APK=$(basename "$APK")
VER=$(echo "$APK" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')
SHA=$(sha256sum "$APK" | awk '{print $1}')
echo "Releasing $APK (version $VER, sha256 $SHA)"

# 1) delete every OTHER apk/idsig/part (old versions) — same place always holds only the latest
for f in kritikart-v*-android-arm64.apk kritikart-v*-android-arm64.apk.idsig; do
  { [ "$f" = "$APK" ] || [ "$f" = "${APK}.idsig" ]; } && continue
  [ -e "$f" ] && rm -f "$f" && echo "deleted $f"
done
rm -f parts/kritikart-*.part*.bin
[ -f "${APK}.idsig" ] || echo "(no idsig for this build)"

# 2) update dl.html: file name, sha, title, badge
sed -i "s|const FILE='kritikart-v[^']*'|const FILE='$APK'|; s|const SHA='[a-f0-9]*'|const SHA='$SHA'|; s|KritiKart v[0-9.]* — הורדה|KritiKart ${VER} — הורדה|; s|badge\">v[0-9.]*<|badge\">${VER}<|" dl.html
grep -q "$APK" dl.html || { echo "ERROR: dl.html not updated"; exit 1; }

# 3) regenerate chat parts (44MB, gateway limit 50MB)
mkdir -p parts
split -b 44M -d -d --numeric-suffixes=0 "$APK" parts/kritikart-${VER}.part
i=0
for p in parts/kritikart-${VER}.part[0-9][0-9]; do mv "$p" "$(echo "$p" | sed "s/part[0-9][0-9]\$/part${i}.bin/")"; i=$((i+1)); done

# 4) verify rejoin + server
R=$(cat parts/kritikart-${VER}.part*.bin | sha256sum | awk '{print $1}')
[ "$R" = "$SHA" ] || { echo "ERROR: rejoin sha mismatch"; exit 1; }
sleep 1
CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://srv1331236.hstgr.cloud/$APK")
echo "server HTTP $CODE | rejoined sha OK"
echo "DONE: https://srv1331236.hstgr.cloud/dl.html -> $APK"
