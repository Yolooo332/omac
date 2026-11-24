#!/bin/bash
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title omac theme
# @raycast.mode compact
# Optional parameters:
# @raycast.icon 🎨
# @raycast.packageName omac
# @raycast.argument1 {"type": "dropdown", "placeholder": "theme", "data": [{"title": "Baby Blue White", "value": "white"}, {"title": "Baby Blue Dark", "value": "dark"}, {"title": "Catppuccin", "value": "catppuccin"}, {"title": "Catppuccin Latte", "value": "catppuccin-latte"}, {"title": "Ethereal", "value": "ethereal"}, {"title": "Everforest", "value": "everforest"}, {"title": "Flexoki Light", "value": "flexoki-light"}, {"title": "Gruvbox", "value": "gruvbox"}, {"title": "Hackerman", "value": "hackerman"}, {"title": "Jade Horse", "value": "jade-horse"}, {"title": "Kanagawa", "value": "kanagawa"}, {"title": "Last Horizon", "value": "last-horizon"}, {"title": "Lumon", "value": "lumon"}, {"title": "Lupine", "value": "lupine"}, {"title": "Matte Black", "value": "matte-black"}, {"title": "Miasma", "value": "miasma"}, {"title": "Nord", "value": "nord"}, {"title": "Retro 82", "value": "retro-82"}, {"title": "Ristretto", "value": "ristretto"}, {"title": "Rose Pine", "value": "rose-pine"}, {"title": "Solitude", "value": "solitude"}, {"title": "Starship", "value": "starship"}, {"title": "Tokyo Night", "value": "tokyo-night"}, {"title": "Vantablack", "value": "vantablack"}, {"title": "Omarchy White", "value": "omarchy-white"}]}
# @raycast.description Switch every app to Baby Blue or an Omarchy theme
# omac script command (from Omarchy). Bind a hotkey to it in Raycast.
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
PATH="$HOME/.local/bin:$PATH"
NO_COLOR=1 omac theme "$1" >/dev/null 2>&1 && echo "Theme: $(omac theme current)" || echo "theme switch failed (run omac doctor)"
