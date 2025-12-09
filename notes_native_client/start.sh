#!/usr/bin/env bash
# Purpose: Non-interactive startup for the Flutter Notes app inside container CI/preview.
# - Verifies Flutter SDK is available
# - Fetches dependencies
# - Tries to run on Linux desktop (if enabled), else prints instructions

set -euo pipefail

WORKSPACE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$WORKSPACE"

echo "[notes_native_client] Checking Flutter SDK availability..."
if ! command -v flutter >/dev/null 2>&1; then
  echo "ERROR: Flutter SDK is not available on PATH." >&2
  echo "Please ensure Flutter SDK is installed in the container and flutter is on PATH." >&2
  echo "Once installed, run: flutter --version" >&2
  exit 1
fi

echo "[notes_native_client] Flutter version:"
flutter --version || true

echo "[notes_native_client] Fetching dependencies (flutter pub get)..."
flutter pub get

# Try to ensure Linux desktop is enabled. This is idempotent and safe if already enabled.
echo "[notes_native_client] Enabling Linux desktop (if supported)..."
flutter config --enable-linux-desktop || true

# Attempt to run the app on Linux desktop non-interactively.
# If no Linux desktop device is available, we fall back to building the app to verify the project compiles.
if flutter devices | grep -qi "linux"; then
  echo "[notes_native_client] Running app on Linux desktop device..."
  # Use --verbose only if troubleshooting; keep default for CI brevity.
  flutter run -d linux --no-fast-start
else
  echo "[notes_native_client] No Linux desktop device found. Building debug bundle instead..."
  # Validate build to catch issues without requiring an emulator/device.
  flutter build linux || {
    echo "Build failed. If Linux desktop is not supported in this image, consider running 'flutter test' instead." >&2
    exit 2
  }
  echo "[notes_native_client] Build succeeded. To run interactively, ensure a device/emulator is configured."
fi
