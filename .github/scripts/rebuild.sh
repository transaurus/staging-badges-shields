#!/usr/bin/env bash
set -euo pipefail

# Rebuild script for badges/shields
# Runs on existing source tree (no clone). Installs deps, runs pre-build steps, builds.

# --- Node version ---
# badges/shields requires Node ^22 || ^24 (engine-strict=true)
if command -v n &>/dev/null; then
    export N_PREFIX="${N_PREFIX:-/usr/local}"
    sudo n 22 2>/dev/null || n 22 2>/dev/null || true
    export PATH="/usr/local/bin:$PATH"
fi

NODE_MAJOR=$(node --version | sed 's/v//' | cut -d. -f1)
if [ "$NODE_MAJOR" -lt 22 ]; then
    echo "[ERROR] Node $NODE_MAJOR detected, but badges/shields requires Node >=22."
    echo "        Install Node 22+ and re-run."
    exit 1
fi
echo "[INFO] Using $(node --version)"

# --- Install dependencies ---
npm ci

# --- Pre-build steps ---
# Generate OpenAPI badge category files into frontend/categories/
npm run defs

# --- Build ---
npm run build

echo "[DONE] Build complete."
