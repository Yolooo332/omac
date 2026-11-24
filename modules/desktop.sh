# wm (Raycast), theme, vscode, apps, extra, macos

# ── wm: Raycast ───────────────────────────────────────────────────────────────
# Raycast does window management, the launcher and clipboard history (Omarchy's
# Super+Space menu and window keys). No tiling manager. Raycast keeps its hotkeys
# in its own database, so omac can't write them: it ships script commands you
# bind in Raycast, and docs/KEYBINDINGS.md lists the Omarchy-style keys to set.
wm_desc() { echo "Raycast window management + omac script commands (no tiling manager)"; }

OMAC_RAYCAST_SCRIPTS="$HOME/.local/share/omac/raycast"

raycast_installed() { [ -d /Applications/Raycast.app ] || [ -d "$HOME/Applications/Raycast.app" ]; }

wm_install() {
  header "Raycast"
  if raycast_installed; then ok "Raycast installed"; else brewfile_install "$OMAC_PATH/packages/Brewfile.wm"; fi
  run chmod +x "$OMAC_PATH"/raycast/*.sh
  ok "omac script commands in $(pretty "$OMAC_RAYCAST_SCRIPTS")"
  info "one-time: Raycast → Settings → Extensions → + → Add Script Directory → $(pretty "$OMAC_RAYCAST_SCRIPTS")"
  info "window hotkeys to set in Raycast: omac keys wm"
  if [ "$OMAC_DRY_RUN" != 1 ] && raycast_installed && ! pgrep -xq Raycast; then open -a Raycast && ok "started Raycast"; fi
  return 0
}

wm_doctor() {
  header "Raycast"
  if raycast_installed; then pass "Raycast installed"; else problem "Raycast not installed" wm; return; fi
  pgrep -xq Raycast && pass "Raycast running" || problem "Raycast isn't running" wm_start
  local bad="" f
  for f in "$OMAC_PATH"/raycast/*.sh; do [ -x "$f" ] || bad="$bad $(basename "$f")"; done
  [ -z "$bad" ] && pass "omac script commands ready" || problem "script commands not executable:$bad" wm
  # Tiling managers and other window tools grab the same hotkeys as Raycast window management
  local other
  for other in AeroSpace yabai Amethyst Rectangle "Rectangle Pro" Magnet Moom Spectacle BetterSnapTool; do
    pgrep -xq "$other" && problem "$other is running and competes with Raycast window management for hotkeys" "" warn
  done
}
fix_wm() { wm_install; }
fix_wm_start() { open -a Raycast && ok "started Raycast"; }

# ── theme ─────────────────────────────────────────────────────────────────────
theme_desc() { echo "Baby Blue (white by default) or any Omarchy theme, across every app"; }

theme_install() { theme_apply "$(setting_get theme "$(theme_current)")"; }

theme_doctor() {
  header "Theme"
  local v
  v="$(theme_current)"
  theme_vars "$v" || { problem "unknown theme '$v'" theme fail; return; }
  if [ -f "$OMAC_THEME_DIR/name" ]; then pass "$T_NAME"; else problem "theme not applied yet" theme fail; return; fi
  local f bad=""
  for f in ghostty.conf tmux.conf shell.zsh; do [ -f "$OMAC_THEME_DIR/$f" ] || bad="$bad $f"; done
  [ -z "$bad" ] || problem "theme state files missing:$bad" theme
  if [ "$T_KIND" = baby-blue ]; then
    grep -qs "theme = $T_GHOSTTY\$" "$OMAC_THEME_DIR/ghostty.conf" || problem "Ghostty isn't on $T_GHOSTTY" theme
    [ -f "$OMAC_CONFIG_HOME/ghostty/themes/$T_GHOSTTY" ] || problem "Ghostty theme file '$T_GHOSTTY' missing" theme
  else
    cmp -s "$T_DIR/ghostty.conf" "$OMAC_THEME_DIR/ghostty.conf" || problem "Ghostty isn't on $T_NAME" theme
  fi
  f="$OMAC_CONFIG_HOME/starship.toml"; [ -f "$f" ] && grep -q '^palette *=' "$f" && { grep -q "^palette = \"$T_STARSHIP\"" "$f" || problem "starship palette isn't $T_STARSHIP" theme; }
  [ "$T_KIND" = omarchy ] && [ -f "$f" ] && grep -q '^palette = "omac"' "$f" && { grep -q "omac-theme-begin ($T_TAG)" "$f" || problem "starship's omac palette isn't $T_NAME" theme; }
  f="$OMAC_CONFIG_HOME/btop/btop.conf"; [ -f "$f" ] && { grep -q "^color_theme = \"$T_BTOP\"" "$f" || problem "btop isn't on $T_BTOP" theme; }
  [ -f "$OMAC_CONFIG_HOME/btop/themes/$T_BTOP.theme" ] || problem "btop theme file $T_BTOP.theme missing" theme
  f="$OMAC_CONFIG_HOME/herdr/config.toml"
  [ -f "$f" ] && { grep -qxF "$(head -n1 "$T_HERDR")" "$f" || problem "herdr isn't on $T_NAME" theme; }
  f="$OMAC_CONFIG_HOME/lazygit/config.yml"; [ -f "$f" ] && { grep -q "omac-theme-begin ($T_TAG)" "$f" || problem "lazygit isn't on $T_NAME" theme; }
  [ "${OMAC_THEME:-$v}" = "$v" ] || note "this shell still has the old theme env; open a new terminal"
}
fix_theme() { theme_apply "$(theme_current)"; }

# ── vscode ────────────────────────────────────────────────────────────────────
vscode_desc() { echo "Baby Blue Theme for VS Code (dark + white)"; }
vscode_code() {
  has code && { command -v code; return; }
  local c="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
  [ -x "$c" ] && printf '%s' "$c"
}
vscode_install() {
  header "VS Code"
  local code vsix
  code="$(vscode_code)"
  [ -n "$code" ] || { info "VS Code not installed; skipping"; return 0; }
  vsix="$(ls "$OMAC_PATH"/themes/baby-blue/vscode/*.vsix 2>/dev/null | tail -n1)"
  [ -n "$vsix" ] || { warn "no .vsix in themes/baby-blue/vscode"; return 0; }
  run "$code" --install-extension "$vsix" --force >/dev/null 2>&1 && ok "installed $(basename "$vsix")"
  info "pick it: Cmd+K Cmd+T → 'Baby Blue Theme White'"
}
vscode_doctor() {
  header "VS Code"
  local code
  code="$(vscode_code)"
  [ -n "$code" ] || { note "VS Code not installed"; return; }
  "$code" --list-extensions 2>/dev/null | grep -qi 'baby-blue' && pass "Baby Blue Theme installed" || problem "Baby Blue Theme extension missing" vscode
}
fix_vscode() { vscode_install; }

# ── apps / extra ──────────────────────────────────────────────────────────────
apps_desc() { echo "Omarchy's default GUI apps (packages/Brewfile.apps)"; }
apps_install() { header "Apps"; brewfile_install "$OMAC_PATH/packages/Brewfile.apps"; }
apps_doctor() {
  header "Apps"
  local m; m="$(brewfile_missing "$OMAC_PATH/packages/Brewfile.apps")"
  [ -z "$m" ] && pass "all apps installed" || note "not installed via Homebrew: $m (omac install apps)"
}
extra_desc() { echo "non-default extras from the Omarchy box (packages/Brewfile.extra)"; }
extra_install() { header "Extras"; brewfile_install "$OMAC_PATH/packages/Brewfile.extra"; }

# ── macos ─────────────────────────────────────────────────────────────────────
macos_desc() { echo "macOS defaults that make it feel like Omarchy (key repeat, drag, Dock, Finder)"; }

# domain|key|type|value|description
macos_defaults_list() {
  cat <<'EOF'
NSGlobalDomain|KeyRepeat|int|2|fast key repeat (Omarchy repeat_rate 40)
NSGlobalDomain|InitialKeyRepeat|int|15|short repeat delay (Omarchy repeat_delay 250)
NSGlobalDomain|ApplePressAndHoldEnabled|bool|false|hold a key to repeat it (vim motions) instead of accent popup
NSGlobalDomain|NSWindowShouldDragOnGesture|bool|true|Ctrl+Cmd+drag moves any window (Omarchy Super+drag)
NSGlobalDomain|NSAutomaticWindowAnimationsEnabled|bool|false|no window open animation
NSGlobalDomain|AppleShowAllExtensions|bool|true|show file extensions
com.apple.dock|autohide|bool|true|hide the Dock (Omarchy has none)
com.apple.dock|mru-spaces|bool|false|don't reorder Spaces
com.apple.finder|AppleShowAllFiles|bool|true|show hidden files in Finder
com.apple.finder|ShowPathbar|bool|true|Finder path bar
com.apple.WindowManager|EnableStandardClickToShowDesktop|bool|false|clicking the wallpaper doesn't hide every window
EOF
}

macos_value_matches() {
  local cur
  cur="$(defaults read "$1" "$2" 2>/dev/null)" || return 1
  case "$3" in
    bool) { [ "$4" = true ] && [ "$cur" = 1 ]; } || { [ "$4" = false ] && [ "$cur" = 0 ]; } ;;
    *) [ "$cur" = "$4" ] ;;
  esac
}

macos_install() {
  header "macOS defaults"
  local d k t v desc changed=0
  while IFS='|' read -r d k t v desc; do
    [ -n "$d" ] || continue
    if macos_value_matches "$d" "$k" "$t" "$v"; then ok "$desc"; continue; fi
    if confirm "$desc?" y; then
      run defaults write "$d" "$k" "-$t" "$v" && ok "$desc"
      changed=1
    fi
  done <<EOF
$(macos_defaults_list)
EOF
  run mkdir -p "$HOME/Pictures/Screenshots"
  if [ "$(defaults read com.apple.screencapture location 2>/dev/null)" != "$HOME/Pictures/Screenshots" ] && confirm "save screenshots to ~/Pictures/Screenshots (Omarchy default)?" y; then
    run defaults write com.apple.screencapture location "$HOME/Pictures/Screenshots"; changed=1
  fi
  if [ $changed = 1 ] && [ "$OMAC_DRY_RUN" != 1 ]; then
    killall Dock Finder SystemUIServer 2>/dev/null || true
    info "key repeat changes need a logout"
  fi
}

macos_doctor() {
  header "macOS defaults"
  local d k t v desc off=""
  while IFS='|' read -r d k t v desc; do
    [ -n "$d" ] || continue
    macos_value_matches "$d" "$k" "$t" "$v" || off="$off
      - $desc"
  done <<EOF
$(macos_defaults_list)
EOF
  [ -z "$off" ] && pass "all Omarchy-style macOS defaults set" || note "optional macOS defaults not set (omac install macos):$off"
}
