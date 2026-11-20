#!/usr/bin/env bash
# Create KritiKart release keystore if missing. Never prints the password.
set -euo pipefail
CRED_DIR=/root/.hermes/secure/credentials
STORE_DIR=/root/.hermes/secure/keystores
KEYSTORE="$CRED_DIR/kritikart-release.keystore"
PASS_FILE="$STORE_DIR/kritikart-release.pass"
ENV_FILE="$STORE_DIR/kritikart-release.keystore.env"
mkdir -p "$CRED_DIR" "$STORE_DIR"
if [[ -f "$KEYSTORE" && -f "$PASS_FILE" ]]; then
  echo "KEYSTORE_ALREADY_PRESENT"
  keytool -list -v -keystore "$KEYSTORE" -alias kritikart -storepass "$(cat "$PASS_FILE")" 2>/dev/null \
    | awk '/SHA256:/{print "CERT_SHA256",$2; exit}'
  exit 0
fi
PASS=$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)
keytool -genkeypair -keystore "$KEYSTORE" -alias kritikart -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass "$PASS" -keypass "$PASS" \
  -dname "CN=KritiKart, OU=Games, O=MaximoSEO, L=Tel Aviv, C=IL" >/tmp/kriti-keytool.out 2>&1
chmod 600 "$KEYSTORE"
printf '%s' "$PASS" > "$PASS_FILE"
chmod 600 "$PASS_FILE"
cp -a "$KEYSTORE" "$STORE_DIR/kritikart-release.keystore"
chmod 600 "$STORE_DIR/kritikart-release.keystore"
umask 077
cat > "$ENV_FILE" <<EOF
KRITIKART_KEYSTORE=$KEYSTORE
KRITIKART_KEYSTORE_ALIAS=kritikart
KRITIKART_KEYSTORE_PASS=$PASS
EOF
chmod 600 "$ENV_FILE"
if [[ -f /root/.env.secrets ]]; then
  if grep -q '^KRITIKART_KEYSTORE_PASS=' /root/.env.secrets; then
    sed -i "s|^KRITIKART_KEYSTORE_PASS=.*|KRITIKART_KEYSTORE_PASS=$PASS|" /root/.env.secrets
  else
    printf 'KRITIKART_KEYSTORE_PASS=%s\n' "$PASS" >> /root/.env.secrets
  fi
else
  printf 'KRITIKART_KEYSTORE_PASS=%s\n' "$PASS" > /root/.env.secrets
  chmod 600 /root/.env.secrets
fi
if command -v doppler >/dev/null 2>&1; then
  doppler secrets set "KRITIKART_KEYSTORE_PASS=$PASS" -p agents -c prd >/tmp/kriti-doppler-set.out 2>&1 || true
fi
unset PASS
echo "KEYSTORE_CREATED"
keytool -list -v -keystore "$KEYSTORE" -alias kritikart -storepass "$(cat "$PASS_FILE")" 2>/dev/null \
  | awk '/SHA256:/{print "CERT_SHA256",$2; exit}'
