# Theme switching. One command flips every app:
#   omac theme white | dark          Baby Blue (omac's own theme)
#   omac theme tokyo-night | nord …  any Omarchy theme (omac theme list)
# State lives in ~/.local/state/omac/theme/ (files apps include), and seeded
# configs that can't include files get their theme line/block patched in place.
# Omarchy themes are pre-generated into themes/omarchy/ by themes/omarchy-themes.py.

BB="$OMAC_PATH/themes/baby-blue"
OT="$OMAC_PATH/themes/omarchy"

theme_current() { cat "$OMAC_THEME_DIR/name" 2>/dev/null || printf white; }

# Canonical theme id for what the user typed ("Tokyo Night" → tokyo-night), or fail.
theme_id() {
  local v
  v="$(printf '%s' "$1" | tr 'A-Z ' 'a-z-' | tr -d "'")"
  case "$v" in
    white|light|baby-blue-white) printf white ;;
    dark|baby-blue|baby-blue-dark) printf dark ;;
    "") return 1 ;;
    *) [ -f "$OT/$v/theme.conf" ] || return 1; printf '%s' "$v" ;;
  esac
}

# Every theme as "id<TAB>mode<TAB>name", Baby Blue first.
theme_list() {
  printf 'white\tlight\tBaby Blue White\n'
  printf 'dark\tdark\tBaby Blue Dark\n'
  [ -f "$OT/LIST" ] && grep -v '^#' "$OT/LIST"
}
theme_ids() { theme_list | cut -f1; }

theme_label() {
  case "$1" in
    white) printf 'Baby Blue White' ;;
    dark) printf 'Baby Blue Dark' ;;
    *) sed -n 's/^name=//p' "$OT/$1/theme.conf" 2>/dev/null ;;
  esac
}

theme_vars() {
  # sets: T_KIND T_NAME T_MODE T_DIR T_GHOSTTY T_BTOP T_HERDR T_STARSHIP T_HERDR_APP T_TMUX T_LAZYGIT T_FZF T_TAG
  T_DIR=""
  case "$1" in
    white) T_GHOSTTY="Baby Blue White"; T_BTOP="baby-blue-white"; T_HERDR="$BB/herdr/baby-blue.toml"; T_STARSHIP="baby_blue_white"; T_HERDR_APP="baby-blue-white"; T_MODE=light ;;
    dark)  T_GHOSTTY="Baby Blue";       T_BTOP="baby-blue";       T_HERDR="$BB/herdr/baby-blue-dark.toml"; T_STARSHIP="baby_blue"; T_HERDR_APP="baby-blue"; T_MODE=dark ;;
  esac
  case "$1" in
    white|dark)
      T_KIND=baby-blue
      T_NAME="$(theme_label "$1")"
      T_TMUX="$BB/tmux/$1.conf"; T_LAZYGIT="$BB/lazygit/$1.yml"; T_FZF="$BB/fzf/$1.zsh"
      T_TAG="Baby Blue $1"
      ;;
    *)
      [ -n "$1" ] && [ -f "$OT/$1/theme.conf" ] || return 1
      T_KIND=omarchy
      T_DIR="$OT/$1"
      T_NAME="$(theme_label "$1")"
      T_MODE="$(sed -n 's/^mode=//p' "$T_DIR/theme.conf")"
      T_GHOSTTY=""
      T_BTOP="omac-$1"; T_HERDR_APP="omac-$1"; T_STARSHIP="omac"
      T_HERDR="$T_DIR/herdr.toml"; T_TMUX="$T_DIR/tmux.conf"; T_LAZYGIT="$T_DIR/lazygit.yml"; T_FZF="$T_DIR/fzf.zsh"
      T_TAG="Omarchy $1"
      ;;
  esac
}

# Swap every [theme...] table in herdr's config.toml for ours, keep the rest.
herdr_apply_theme() {
  local cfg="$1" src="$2" tmp
  [ -f "$cfg" ] || return 0
  [ "$OMAC_DRY_RUN" = 1 ] && { info "[dry-run] herdr [theme] ← $(basename "$src")"; return 0; }
  backup_copy "$cfg"
  tmp="$cfg.omac.tmp"
  awk '
    /^[[:space:]]*\[/ {
      name = $0; gsub(/^[[:space:]]*\[+|\]+.*$/, "", name)
      skip = (name ~ /^theme/)
      if (skip) { while (n > 0 && buf[n] ~ /^[[:space:]]*#/) n-- }
    }
    !skip { buf[++n] = $0 }
    END {
      while (n > 0 && buf[n] ~ /^[[:space:]]*$/) n--
      for (i = 1; i <= n; i++) print buf[i]
    }
  ' "$cfg" >"$tmp"
  { cat "$tmp"; printf '\n'; cat "$src"; } >"$cfg"
  rm -f "$tmp"
}

theme_apply() {
  local v
  v="$(theme_id "${1:-white}")" || die "unknown theme '$1' (see: omac theme list)"
  theme_vars "$v"
  header "Theme: $T_NAME"

  run mkdir -p "$OMAC_THEME_DIR"
  if [ "$OMAC_DRY_RUN" != 1 ]; then
    printf '%s\n' "$v" >"$OMAC_THEME_DIR/name"
    if [ "$T_KIND" = baby-blue ]; then
      printf '# omac theme (generated)\ntheme = %s\n' "$T_GHOSTTY" >"$OMAC_THEME_DIR/ghostty.conf"
    else
      cp "$T_DIR/ghostty.conf" "$OMAC_THEME_DIR/ghostty.conf"
    fi
    cp "$T_TMUX" "$OMAC_THEME_DIR/tmux.conf"
    {
      printf '# omac theme (generated): sourced by omac zsh init\n'
      printf 'export OMAC_THEME=%s\n' "$v"
      cat "$T_FZF"
      # Baby Blue's ls colors (colors only: omac's aliases, Omarchy's ls/lt, stay in charge).
      # Omarchy themes keep eza's defaults, as on Omarchy.
      [ "$T_KIND" = baby-blue ] && sed '/^if command -v eza/,/^fi/d' "$BB/shell/ls-colors.zsh"
    } >"$OMAC_THEME_DIR/shell.zsh"
  fi
  ok "state files in $(pretty "$OMAC_THEME_DIR")"

  # Theme assets each app looks up by name
  run mkdir -p "$OMAC_CONFIG_HOME/ghostty/themes" "$OMAC_CONFIG_HOME/btop/themes" "$OMAC_CONFIG_HOME/herdr-app/themes"
  run cp "$BB/ghostty/themes/Baby Blue" "$BB/ghostty/themes/Baby Blue White" "$OMAC_CONFIG_HOME/ghostty/themes/"
  run cp "$BB/btop/themes/"*.theme "$OMAC_CONFIG_HOME/btop/themes/"
  run cp "$BB/herdr-app/themes/"*.json "$OMAC_CONFIG_HOME/herdr-app/themes/"
  if [ "$T_KIND" = omarchy ]; then
    run cp "$T_DIR/btop.theme" "$OMAC_CONFIG_HOME/btop/themes/$T_BTOP.theme"
    run cp "$T_DIR/herdr-app.json" "$OMAC_CONFIG_HOME/herdr-app/themes/$T_HERDR_APP.json"
  fi
  ok "theme files for ghostty, btop, herdr app"

  # herdr CLI
  if [ -f "$OMAC_CONFIG_HOME/herdr/config.toml" ]; then
    herdr_apply_theme "$OMAC_CONFIG_HOME/herdr/config.toml" "$T_HERDR"
    ok "herdr [theme] → $T_NAME"
  fi

  # starship palette line (+ the "omac" palette block for Omarchy themes)
  local f="$OMAC_CONFIG_HOME/starship.toml"
  if [ -f "$f" ] && grep -q '^palette *=' "$f"; then
    backup_copy "$f"
    [ "$T_KIND" = omarchy ] && replace_block "$f" "$T_DIR/starship.toml"
    run sed -i '' "s/^palette *=.*/palette = \"$T_STARSHIP\"/" "$f"
    ok "starship palette → $T_STARSHIP"
  fi

  # btop rewrites btop.conf itself, so only touch the theme line
  f="$OMAC_CONFIG_HOME/btop/btop.conf"
  if [ -f "$f" ]; then
    backup_copy "$f"
    if grep -q '^color_theme' "$f"; then
      run sed -i '' "s|^color_theme *=.*|color_theme = \"$T_BTOP\"|" "$f"
    else
      [ "$OMAC_DRY_RUN" = 1 ] || printf 'color_theme = "%s"\n' "$T_BTOP" >>"$f"
    fi
    ok "btop → $T_BTOP"
  fi

  # lazygit theme block
  f="$OMAC_CONFIG_HOME/lazygit/config.yml"
  if [ -f "$f" ]; then
    replace_block "$f" "$T_LAZYGIT"
    ok "lazygit theme block"
  fi

  theme_reload
  info "Neovim picks the theme up on next start."
  if [ "$T_KIND" = baby-blue ]; then
    info "herdr app: choose '$T_HERDR_APP' in its settings. VS Code: 'Baby Blue Theme$( [ "$v" = white ] && printf ' White')'."
  else
    info "herdr app: choose '$T_HERDR_APP' in its settings."
    if [ -f "$T_DIR/vscode.json" ]; then
      local ext name
      ext="$(sed -n 's/.*"extension": *"\([^"]*\)".*/\1/p' "$T_DIR/vscode.json")"
      name="$(sed -n 's/.*"name": *"\([^"]*\)".*/\1/p' "$T_DIR/vscode.json")"
      info "VS Code: install '$ext', then pick '$name' (Cmd+K Cmd+T)."
    fi
  fi
}

# Tell running apps to pick the theme up.
theme_reload() {
  [ "$OMAC_DRY_RUN" = 1 ] && return 0
  if has tmux && tmux info >/dev/null 2>&1; then
    tmux source-file "$OMAC_THEME_DIR/tmux.conf" >/dev/null 2>&1 && ok "reloaded tmux"
  fi
  if has herdr && herdr status server >/dev/null 2>&1; then
    herdr server reload-config >/dev/null 2>&1 && ok "reloaded herdr"
  fi
  if pgrep -xq ghostty 2>/dev/null || pgrep -q -f Ghostty.app 2>/dev/null; then
    info "Ghostty: press Cmd+Shift+, to reload its config"
  fi
}
