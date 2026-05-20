#!/bin/bash
# ==========================================================
# Enigma CryptoShelter — Tebako build script
# Generates single executable for current platform
# Usage: ./package/build.sh
# ==========================================================
set -e

APP_NAME="enigma_cryptoshelter"
RUBY_VERSION="3.2.2"

echo "╔══════════════════════════════════════╗"
echo "║   Enigma CryptoShelter — Packaging   ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "Platform: $(uname -s)"
echo "Ruby:     $(ruby --version)"
echo "Tebako:   $(tebako --version)"
echo ""

# Ensure dist directory exists
mkdir -p dist

# Detect platform for output naming
case "$(uname -s)" in
  Linux*)
    OUTPUT="dist/${APP_NAME}_linux"
    ;;
  Darwin*)
    OUTPUT="dist/${APP_NAME}_mac"
    ;;
  *)
    OUTPUT="dist/${APP_NAME}"
    ;;
esac

echo "Building → ${OUTPUT}"
echo ""

# Run Tebako press (package the app)
tebako press \
  --root . \
  --entry-point main.rb \
  --output "${OUTPUT}" \
  --Ruby "${RUBY_VERSION}"

echo ""
echo "✅ Build complete: ${OUTPUT}"
echo ""
echo "Test with:"
echo "  ${OUTPUT}"

chmod +x "$OUTPUT"
