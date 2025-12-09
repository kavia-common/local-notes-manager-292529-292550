#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/local-notes-manager-292529-292550/notes_native_client"
# Persist minimal env for future shells
ENVFILE=/etc/profile.d/dev_env.sh
if [ ! -f "$ENVFILE" ]; then
  sudo bash -lc "cat > $ENVFILE <<'EOF'
export NODE_ENV=development
export BUILD_TARGET=linux
EOF"
fi
cd "$WORKSPACE"
# Validate Node/npm availability and versions
NODE_BIN=$(command -v node || true)
NPM_BIN=$(command -v npm || true)
if [ -z "$NODE_BIN" ] || [ -z "$NPM_BIN" ]; then
  echo "node and npm must be available on PATH" >/dev/stderr
  exit 2
fi
NODE_VER=$($NODE_BIN -v | sed 's/^v//')
NPM_VER=$($NPM_BIN -v)
# simple numeric compare for major versions
NODE_MAJOR=${NODE_VER%%.*}
NPM_MAJOR=${NPM_VER%%.*}
if [ "${NODE_MAJOR:-0}" -lt 18 ] || [ "${NPM_MAJOR:-0}" -lt 9 ]; then
  echo "Require node>=18 and npm>=9 (found node $NODE_VER npm $NPM_VER)" >/dev/stderr
  exit 3
fi
# Backup existing package.json if present
if [ -f package.json ]; then
  cp -n package.json package.json.bak || true
fi
# If package.json missing or empty, repair scaffold and ensure files
if [ ! -f package.json ] || [ ! -s package.json ]; then
  echo 'Repairing scaffold: creating package.json and scaffold files' >/dev/stderr
  npm init -y >/dev/null || true
  node - <<'NODE'
const fs=require('fs'),p=fs.existsSync('package.json')?JSON.parse(fs.readFileSync('package.json')):{};
p.name=p.name||'local-notes-manager';p.version=p.version||'0.1.0';p.main=p.main||'src/main.js';p.scripts=p.scripts||{};
if(!p.scripts.start) p.scripts.start='./node_modules/.bin/electron .';
if(!p.scripts.test) p.scripts.test='./node_modules/.bin/jest --config jest.config.js --runInBand';
if(!p.scripts.build) p.scripts.build='./node_modules/.bin/electron-builder --linux --dir || echo "pack skipped"';
p.dependencies=p.dependencies||{}; p.devDependencies=p.devDependencies||{};
if(!p.devDependencies.electron) p.devDependencies.electron='^26.0.0';
if(!p.dependencies.sqlite3) p.dependencies.sqlite3='^5.1.6';
if(!p.devDependencies.jest) p.devDependencies.jest='^29.6.1';
if(!p.devDependencies['electron-builder']) p.devDependencies['electron-builder']='^24.7.0';
fs.writeFileSync('package.json',JSON.stringify(p,null,2));
NODE
  mkdir -p src __tests__ || true
  cat > "$WORKSPACE/src/index.html" <<'HTML'
<!doctype html><html><body><h1>Local Notes Manager (Dev)</h1><div id="status">ready</div><script>console.log('renderer up');</script></body></html>
HTML
  cat > "$WORKSPACE/jest.config.js" <<'J'
module.exports={testEnvironment:'node'}
J
  cat > "$WORKSPACE/__tests__/storage.test.js" <<'T'
const s=require('../src/storage');
test('list returns array', done=>{ s.list((e,rows)=>{ if(e) return done(e); expect(Array.isArray(rows)).toBe(true); done(); }); });
T
fi
# Ensure src/storage.js exists (simple sqlite3-backed API) without overwriting
if [ ! -f src/storage.js ]; then
  cat > src/storage.js <<'S'
const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('notes.db');
module.exports.list = cb => db.all('SELECT 1 AS ok', cb);
S
fi
# Reinstall dependencies: prefer npm ci when lockfile exists; fall back to npm install
export PYTHON=$(command -v python3 || command -v python || true) || true
cd "$WORKSPACE"
if [ -f package-lock.json ]; then
  npm ci --no-audit --no-fund --prefer-offline --silent || npm install --no-audit --no-fund --silent
else
  npm install --no-audit --no-fund --silent || (echo 'npm install failed' >/dev/stderr && exit 4)
fi
# Post-install validation
if [ ! -d node_modules ] || [ ! -f node_modules/.bin/jest ]; then
  echo 'Dependency install appears to have failed: node_modules or local binaries missing' >/dev/stderr
  # If sqlite3 failed to build, suggest libsqlite3-dev (non-fatal here but instructive)
  if ! grep -q sqlite3 package.json 2>/dev/null; then :; else
    echo 'If sqlite3 native build failed, ensure libsqlite3-dev and build-essential are installed: sudo apt-get install -y libsqlite3-dev' >/dev/stderr
  fi
  exit 5
fi
# Ensure package-lock.json exists to stabilize subsequent runs
if [ ! -f package-lock.json ]; then
  npm i --package-lock-only --silent || true
fi
echo 'scaffold repair and reinstall completed' >/dev/stderr
