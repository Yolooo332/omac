#!/bin/bash
# omac bootstrap: Omarchy's setup for macOS.
#
#   From a checkout:   ./install.sh [omac install flags]
#   Fresh Mac:         bash -c "$(curl -fsSL https://raw.githubusercontent.com/Yolooo332/omac/main/install.sh)"
#
# Installs Xcode CLT + Homebrew if needed, puts the repo at ~/.local/share/omac,
# then runs `omac install` (which asks before replacing any config you made).
set -eo pipefail

OMAC_REPO="${OMAC_REPO:-https://github.com/Yolooo332/omac.git}"
TARGET="$HOME/.local/share/omac"

[ "$(uname -s)" = Darwin ] || { echo "omac is for macOS" >&2; exit 1; }

here="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd -P || true)"

if ! xcode-select -p >/dev/null 2>&1; then
  echo "› Installing Xcode Command Line Tools. Re-run this script when the installer finishes."
  xcode-select --install || true
  exit 1
fi

if [ -n "$here" ] && [ -x "$here/bin/omac" ]; then
  SRC="$here"
elif [ -n "$OMAC_REPO" ]; then
  if [ -d "$TARGET/.git" ]; then
    git -C "$TARGET" pull --ff-only
  else
    mkdir -p "$(dirname "$TARGET")"
    git clone "$OMAC_REPO" "$TARGET"
  fi
  SRC="$TARGET"
else
  echo "Run this from an omac checkout, or set OMAC_REPO=<git url>." >&2
  exit 1
fi

exec "$SRC/bin/omac" install "$@"
