#!/bin/bash
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title omac update
# @raycast.mode silent
# Optional parameters:
# @raycast.icon ⬆️
# @raycast.packageName omac
# @raycast.description Omarchy: Update
# omac script command (from Omarchy). Bind a hotkey to it in Raycast.
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
PATH="$HOME/.local/bin:$PATH"
exec omac term "omac update; read -k1 \"?press a key\""
