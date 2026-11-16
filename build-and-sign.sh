#!/bin/bash
# Builds, signs, notarizes and staples the Gigabits Mac installer. Run on a Mac, from this folder:
#   chmod +x build-and-sign.sh && ./build-and-sign.sh
# One-time setup first (see the steps Claude gave you):
#   1. A "Developer ID Installer" certificate in your keychain.
#   2. Notary credentials saved under the name "gigabits-notary".
set -euo pipefail
cd "$(dirname "$0")"

OUT="Gigabits-Setup.pkg"
PROFILE="${NOTARY_PROFILE:-gigabits-notary}"

IDENTITY=$(security find-identity -v | grep "Developer ID Installer" | head -1 | sed -E 's/.*"(.*)".*/\1/')
if [ -z "$IDENTITY" ]; then
  echo "No 'Developer ID Installer' certificate found in your keychain. Create it first (step 2)."; exit 1
fi
echo "Signing with: $IDENTITY"

chmod 755 scripts/postinstall
rm -f "$OUT"

# A scripts-only package: nothing is copied to the Mac, it just runs scripts/postinstall.
pkgbuild --nopayload --scripts scripts \
  --identifier com.gigabitstech.protection-setup --version 1.0 \
  --sign "$IDENTITY" "$OUT"

echo "Sending to Apple for notarization (usually a few minutes)..."
xcrun notarytool submit "$OUT" --keychain-profile "$PROFILE" --wait

xcrun stapler staple "$OUT"

echo
echo "Check (should say: accepted, source=Notarized Developer ID):"
spctl -a -vv -t install "$OUT" || true
echo
echo "Done: $(pwd)/$OUT"
echo "To test, copy it as Gigabits-Setup-GB-XXXXXXXX.pkg (your real code) and double-click the copy."
