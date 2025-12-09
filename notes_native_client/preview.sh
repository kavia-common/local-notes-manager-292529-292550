#!/usr/bin/env bash
# Thin wrapper used by the preview runner to start the Flutter app.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$SCRIPT_DIR/start.sh"
