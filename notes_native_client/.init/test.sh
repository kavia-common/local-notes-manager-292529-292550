#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/local-notes-manager-292529-292550/notes_native_client"
cd "$WORKSPACE"
if [ ! -f package.json ] || [ ! -s package.json ]; then echo "package.json missing or empty; run scaffold-repair-001 to recreate and reinstall" >&2; exit 2; fi
if [ ! -d node_modules ]; then echo "node_modules missing; run deps-001" >&2; exit 3; fi
if [ ! -x ./node_modules/.bin/jest ]; then echo "local jest runner missing; run deps-001 to install dependencies" >&2; exit 4; fi
rm -f src/notes.db || true
./node_modules/.bin/jest --config jest.config.js --runInBand --silent
