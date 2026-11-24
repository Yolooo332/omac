#!/bin/bash
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title omac doctor
# @raycast.mode fullOutput
# Optional parameters:
# @raycast.icon 🩺
# @raycast.packageName omac
# @raycast.description Check for problems and conflicts
# omac script command (from Omarchy). Bind a hotkey to it in Raycast.
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
PATH="$HOME/.local/bin:$PATH"
NO_COLOR=1 omac doctor 2>&1
