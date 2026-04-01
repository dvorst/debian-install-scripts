#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# install_drawio.sh
#   Downloads and installs the latest draw.io AMD64 .deb
#   Skips download if the latest version is already installed
#   Installs newer version if available.
# ---------------------------------------------------------------------------

DEB_DIR="/tmp"
RELEASES_URL="https://github.com/jgraph/drawio-desktop/releases/latest"
PACKAGE_NAME="draw.io"

echo "==> Fetching latest draw.io release info..."

# Resolve the redirect from /releases/latest to get the actual tag (e.g. v26.0.3)
LATEST_TAG=$(curl -fsSL -o /dev/null -w '%{url_effective}' "$RELEASES_URL" \
  | grep -oP 'v[\d.]+$')

if [[ -z "$LATEST_TAG" ]]; then
  echo "ERROR: Could not determine the latest release tag." >&2
  exit 1
fi

LATEST_VERSION="${LATEST_TAG#v}"   # strip leading 'v'
echo "==> Latest release: ${LATEST_VERSION}"

# Check currently installed version (if any)
INSTALLED_VERSION=""
if dpkg -s "$PACKAGE_NAME" &>/dev/null; then
  INSTALLED_VERSION=$(dpkg-query -W -f='${Version}' "$PACKAGE_NAME" 2>/dev/null || true)
fi

# echo info
if [[ -n "$INSTALLED_VERSION" ]]; then
  echo "==> Installed version: ${INSTALLED_VERSION}"
  if [[ "$INSTALLED_VERSION" == "$LATEST_VERSION" ]]; then
    echo "==> draw.io ${LATEST_VERSION} is already installed and up to date. Nothing to do."
    exit 0
  else
    echo "==> Newer version available (${INSTALLED_VERSION} -> ${LATEST_VERSION}). Proceeding with upgrade..."
  fi
else
  echo "==> draw.io is not currently installed. Proceeding with fresh install..."
fi

# Build the download URL
DEB_FILENAME="drawio-amd64-${LATEST_VERSION}.deb"
DOWNLOAD_URL="https://github.com/jgraph/drawio-desktop/releases/download/${LATEST_TAG}/${DEB_FILENAME}"
DEB_PATH="${DEB_DIR}/${DEB_FILENAME}"

# Download (skip if already downloaded for this version)
if [[ -f "$DEB_PATH" ]]; then
  echo "==> Package already downloaded at ${DEB_PATH}. Skipping download."
else
  echo "==> Downloading ${DEB_FILENAME}..."
  curl -fsSL --progress-bar -L "$DOWNLOAD_URL" -o "$DEB_PATH"
  echo "==> Downloaded to ${DEB_PATH}"
fi

# Install
echo "==> Installing ${DEB_FILENAME}..."
sudo apt-get install -y "$DEB_PATH"

# Verify
INSTALLED_NOW=$(dpkg-query -W -f='${Version}' "$PACKAGE_NAME" 2>/dev/null || true)
if [[ "$INSTALLED_NOW" == "$LATEST_VERSION" ]]; then
  echo "==> draw.io ${LATEST_VERSION} installed successfully."
else
  echo "ERROR: Installation may have failed. Reported version: '${INSTALLED_NOW}'" >&2
  exit 1
fi
