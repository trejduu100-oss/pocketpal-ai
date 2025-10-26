#!/usr/bin/env bash
set -euo pipefail

# CrywereGPT local dev setup script
# - Installs dependencies for backend and web (if present)
# - Builds or starts the web dev server
# - Starts the backend server (if present)
# - Designed to run on Linux/macOS environments

ROOT_DIR="$(cd ""$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "== CrywereGPT Local Dev Setup =="

# Backend setup
if [ -d "$ROOT_DIR/backend" ]; then
  echo "--> Found backend/ directory. Installing backend dependencies..."
  cd "$ROOT_DIR/backend"
  if [ -f package-lock.json ] || [ -f package.json ]; then
    npm ci || npm install
  fi

  # Start backend if server.js exists
  if [ -f server.js ]; then
    echo "--> Starting backend (node server.js) in background on default port 5000..."
    node server.js &
    BACKEND_PID=$!
    echo "--> Backend PID: $BACKEND_PID"
  else
    echo "--> No server.js found in backend/ — skipping auto-start."
  fi
  cd "$ROOT_DIR"
fi

# Web setup
WEB_DIR="$ROOT_DIR/web"
if [ -d "$WEB_DIR" ]; then
  echo "--> Found web/ directory. Installing web dependencies..."
  cd "$WEB_DIR"
  npm ci || npm install

  # Prefer common dev scripts: dev -> start -> build+serve
  if grep -q '"dev"' package.json 2>/dev/null; then
    echo "--> Running: npm run dev"
    npm run dev
  elif grep -q '"start"' package.json 2>/dev/null; then
    echo "--> Running: npm start"
    npm start
  else
    echo "--> No dev/start script found. Building static site and serving on port 3000..."
    npm run build
    if ! command -v serve >/dev/null 2>&1; then
      echo "---- installing 'serve' for static hosting (npm i -g serve)"
      npm install -g serve
    fi
    serve -s build -l 3000
  fi
  cd "$ROOT_DIR"
else
  # No web/ folder: try to use root package.json (monorepo-less projects)
  if [ -f "$ROOT_DIR/package.json" ]; then
    echo "--> No web/ folder but found root package.json. Installing and starting root app..."
    cd "$ROOT_DIR"
    npm ci || npm install
    if grep -q '"dev"' package.json 2>/dev/null; then
      npm run dev
    elif grep -q '"start"' package.json 2>/dev/null; then
      npm start
    else
      echo "--> No dev/start script at root. Nothing to start for web UI."
    fi
  else
    echo "--> No web/ or root package.json found. Skipping web setup."
  fi
fi

# Summary / hints
echo "\n== Summary =="
if [ ! -z "${BACKEND_PID-}" ]; then
  echo "Backend: running (PID=$BACKEND_PID) — check http://localhost:5000 or your backend's configured port"
else
  echo "Backend: not started by this script"
fi

if [ -d "$WEB_DIR" ]; then
  echo "Web: running — try http://localhost:3000 (or the dev server's port)"
else
  echo "Web: not started by this script"
fi

echo "If you need to build llama.cpp locally (native inference), see docs/PLATFORM.md for build instructions."