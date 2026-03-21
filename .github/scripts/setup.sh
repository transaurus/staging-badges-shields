#!/usr/bin/env bash
set -euo pipefail

# Setup script for badges/shields Docusaurus i18n
# Repo: https://github.com/badges/shields
# Docusaurus: 3.9.2, site directory: frontend/, config: frontend/docusaurus.config.cjs
# Package manager: npm, Node: 22+

REPO_URL="https://github.com/badges/shields"
REPO_DIR="source-repo"
NODE_VERSION="22"

# Use nvm to get Node 22
export NVM_DIR="${HOME}/.nvm"
if [ -f "${NVM_DIR}/nvm.sh" ]; then
  # shellcheck source=/dev/null
  source "${NVM_DIR}/nvm.sh"
  nvm install "${NODE_VERSION}"
  nvm use "${NODE_VERSION}"
else
  echo "nvm not found, using system node: $(node --version)"
fi

echo "Node: $(node --version)"
echo "npm: $(npm --version)"

# Clone repo
if [ ! -d "${REPO_DIR}" ]; then
  git clone --depth=1 "${REPO_URL}" "${REPO_DIR}"
fi

cd "${REPO_DIR}"

# Install root dependencies (Docusaurus is installed at root)
npm install --legacy-peer-deps

# Run write-translations — site directory is frontend/
# This mirrors the pattern: "docusaurus:start": "docusaurus start frontend"
npx docusaurus write-translations frontend

echo "SUCCESS: i18n files written"
