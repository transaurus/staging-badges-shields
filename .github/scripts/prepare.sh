#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/badges/shields"
BRANCH="master"
REPO_DIR="source-repo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Clone (skip if already exists) ---
if [ ! -d "$REPO_DIR" ]; then
    git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
fi

cd "$REPO_DIR"

# --- Node version ---
# badges/shields requires Node ^22 || ^24 (engine-strict=true)
# Use n to install and activate Node 22
if command -v n &>/dev/null; then
    export N_PREFIX="${N_PREFIX:-/usr/local}"
    sudo n 22 2>/dev/null || n 22 2>/dev/null || true
    # Ensure the correct node is on PATH
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
# badges/shields uses npm (package-lock.json present)
# engine-strict=true in .npmrc so Node version must be >=22
npm ci

# --- Pre-build steps ---
# Generate OpenAPI badge category files into frontend/categories/
# This is required before docusaurus build or write-translations
npm run defs

# --- Apply fixes.json if present ---
FIXES_JSON="$SCRIPT_DIR/fixes.json"
if [ -f "$FIXES_JSON" ]; then
    echo "[INFO] Applying content fixes..."
    node -e "
    const fs = require('fs');
    const path = require('path');
    const fixes = JSON.parse(fs.readFileSync('$FIXES_JSON', 'utf8'));
    for (const [file, ops] of Object.entries(fixes.fixes || {})) {
        if (!fs.existsSync(file)) { console.log('  skip (not found):', file); continue; }
        let content = fs.readFileSync(file, 'utf8');
        for (const op of ops) {
            if (op.type === 'replace' && content.includes(op.find)) {
                content = content.split(op.find).join(op.replace || '');
                console.log('  fixed:', file, '-', op.comment || '');
            }
        }
        fs.writeFileSync(file, content);
    }
    for (const [file, cfg] of Object.entries(fixes.newFiles || {})) {
        const c = typeof cfg === 'string' ? cfg : cfg.content;
        fs.mkdirSync(path.dirname(file), {recursive: true});
        fs.writeFileSync(file, c);
        console.log('  created:', file);
    }
    "
fi

echo "[DONE] Repository is ready for docusaurus commands."
