#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="/home/kavia/workspace/code-generation/local-notes-manager-292529-292550/notes_native_client"
cd "$WORKSPACE"
# ensure python path exported for node-gyp
export PYTHON=$(command -v python3 || true)
# prefer npm ci when lockfile is present; fallback to npm install on failure
if [ -f package-lock.json ]; then
  if ! npm ci --no-audit --no-fund --prefer-offline --silent; then
    echo "npm ci failed; falling back to npm install" >&2
    npm install --no-audit --no-fund --silent
  fi
else
  npm install --no-audit --no-fund --silent || true
fi
# If package.json references sqlite3, ensure it installed correctly; give remediation if it failed
if [ -f package.json ] && grep -q '"sqlite3"' package.json 2>/dev/null; then
  if [ ! -d node_modules/sqlite3 ] && [ ! -f node_modules/sqlite3/package.json ]; then
    echo "ERROR: sqlite3 did not install cleanly. Native build likely failed." >&2
    echo "Remediation: install system SQLite dev headers and re-run: sudo apt-get update && sudo apt-get install -y libsqlite3-dev" >&2
    echo "Alternatively, consider switching to a pure-js binding (better-sqlite3 or sqlite3 prebuilt) or using a compatible node version." >&2
    exit 10
  fi
fi
# verify local binaries exist
if [ ! -x ./node_modules/.bin/electron ]; then
  echo "local electron binary missing: ./node_modules/.bin/electron" >&2; exit 11
fi
if [ ! -x ./node_modules/.bin/jest ]; then
  echo "local jest binary missing: ./node_modules/.bin/jest" >&2; exit 12
fi
# non-strict package.json check for expected deps
node -e "try{const p=require('./package.json');const miss=[]; if(!((p.devDependencies&&p.devDependencies.electron)||(p.dependencies&&p.dependencies.electron))) miss.push('electron'); if(!((p.devDependencies&&p.devDependencies.jest)||(p.dependencies&&p.dependencies.jest))) miss.push('jest'); if(miss.length){ console.warn('package.json missing expected deps:',miss); process.exitCode=0; }}catch(e){console.warn('package.json read failed:',e.message);}" || true
