# git, mise, tools (starship, lazygit, btop, try, fastfetch)

# ── git ───────────────────────────────────────────────────────────────────────
git_desc() { echo "Omarchy git defaults (~/.config/git/config), identity stays in ~/.gitconfig"; }

git_install() {
  header "Git"
  seed "$OMAC_PATH/config/git/config" "$OMAC_CONFIG_HOME/git/config"
  seed "$OMAC_PATH/config/git/ignore" "$OMAC_CONFIG_HOME/git/ignore"
  if [ -z "$(git config --global user.name 2>/dev/null)" ] && [ -t 0 ] && [ "$OMAC_DRY_RUN" != 1 ]; then
    local n e
    printf '  Git name: '; read -r n </dev/tty
    printf '  Git email: '; read -r e </dev/tty
    [ -n "$n" ] && git config --file "$HOME/.gitconfig" user.name "$n"
    [ -n "$e" ] && git config --file "$HOME/.gitconfig" user.email "$e"
  fi
  return 0
}

git_doctor() {
  header "Git"
  check_file "$OMAC_CONFIG_HOME/git/config" git_seed "omac git defaults"
  if [ -n "$(git config --global user.name)" ] && [ -n "$(git config --global user.email)" ]; then
    pass "identity: $(git config --global user.name)"
  else
    problem "git user.name/user.email not set" git_identity
  fi
  # ~/.gitconfig is read after ~/.config/git/config, so its values win. Show where they disagree.
  if [ -f "$HOME/.gitconfig" ] && [ -f "$OMAC_CONFIG_HOME/git/config" ]; then
    local k v1 v2
    while IFS= read -r k; do
      [ -n "$k" ] || continue
      case "$k" in user.*|credential.*|include*) continue ;; esac
      v1="$(git config --file "$OMAC_CONFIG_HOME/git/config" --get "$k" 2>/dev/null)" || continue
      v2="$(git config --file "$HOME/.gitconfig" --get "$k" 2>/dev/null)"
      [ "$v1" != "$v2" ] && note "git $k: ~/.gitconfig says '$v2', overriding omac's '$v1' (fine if intended)"
    done <<EOF
$(git config --file "$HOME/.gitconfig" --list --name-only 2>/dev/null | sort -u)
EOF
  fi
  has gh && { gh auth status >/dev/null 2>&1 && pass "gh is logged in" || note "gh not logged in (gh auth login)"; }
}
fix_git_seed() { git_install; }
fix_git_identity() { OMAC_DRY_RUN=0 git_install; }

# ── mise ──────────────────────────────────────────────────────────────────────
mise_desc() { echo "mise + Omarchy's lazy dev tools and AI agents (~/.config/mise/conf.d/omac.toml)"; }

# Command each declared tool provides (only where it differs from the tool name)
mise_tool_cmd() {
  case "$1" in
    "npm:@google/gemini-cli") echo gemini ;;
    *) echo "$1" ;;
  esac
}

# The tool list minus anything you already have (npm -g, brew, curl installer, your
# own mise config...): omac never installs a second copy of a tool.
mise_filtered_toml() {
  local out="$1" line tool cmd p
  : >"$out"
  while IFS= read -r line; do
    case "$line" in
      [a-z\"]*"= {"*)
        tool="$(printf '%s' "$line" | sed -E 's/^"?([^"=]+)"? *=.*/\1/' | sed 's/ *$//')"
        cmd="$(mise_tool_cmd "$tool")"
        p="$(type -ap "$cmd" 2>/dev/null | grep -v '/mise/shims/' | head -n1)"
        if [ -n "$p" ]; then
          printf '# %s  # omac: skipped, already installed at %s\n' "$line" "$(pretty "$p")" >>"$out"
          info "$tool: already installed at $(pretty "$p"), not adding it"
          continue
        fi
        ;;
    esac
    printf '%s\n' "$line" >>"$out"
  done <"$OMAC_PATH/config/mise/omac.toml"
}

mise_install() {
  header "mise"
  local gen="$OMAC_STATE/mise-omac.toml"
  run mkdir -p "$OMAC_STATE"
  if [ "$OMAC_DRY_RUN" = 1 ]; then gen="$OMAC_PATH/config/mise/omac.toml"; mkdir -p "$OMAC_STATE" 2>/dev/null; mise_filtered_toml /dev/null; else mise_filtered_toml "$gen"; fi
  seed "$gen" "$OMAC_CONFIG_HOME/mise/conf.d/omac.toml"
  if has mise; then
    run mise trust -q "$OMAC_CONFIG_HOME/mise/conf.d/omac.toml" >/dev/null 2>&1 || true
    run mise reshim >/dev/null 2>&1 || true
    ok "mise $(mise --version 2>/dev/null | awk '{print $1}') (tools install on first use; 'mise install --include-lazy' to fetch all now)"
  fi
  return 0
}

mise_doctor() {
  header "mise"
  if ! has mise; then problem "mise not installed" brew_bundle fail; return; fi
  pass "mise $(mise --version 2>/dev/null | awk '{print $1}') at $(pretty "$(command -v mise)")"
  check_file "$OMAC_CONFIG_HOME/mise/conf.d/omac.toml" mise_seed "omac tool list"
  local errs
  errs="$(mise ls --current 2>&1 >/dev/null | grep -iE 'error|invalid|parse' | head -n 3)"
  [ -n "$errs" ] && problem "mise config errors: $errs" "" fail
  # Tools installed both by mise and another way (npm -g under a mise node, brew, curl installers)
  check_duplicates claude codex opencode gemini node python uv bun go
}
fix_mise_seed() { mise_install; }

# ── tools: starship, lazygit, btop, try ──────────────────────────────────────
tools_desc() { echo "starship prompt, lazygit, btop, try (themed by omac theme)"; }

tools_install() {
  header "Tools"
  seed "$OMAC_PATH/config/starship.toml" "$OMAC_CONFIG_HOME/starship.toml"
  seed "$OMAC_PATH/config/lazygit/config.yml" "$OMAC_CONFIG_HOME/lazygit/config.yml"
  # btop rewrites its own config (dropping our marker), so only seed when absent
  if [ -f "$OMAC_CONFIG_HOME/btop/btop.conf" ]; then
    ok "~/.config/btop/btop.conf (yours; omac only sets color_theme)"
  else
    seed "$OMAC_PATH/config/btop/btop.conf" "$OMAC_CONFIG_HOME/btop/btop.conf"
  fi

  # try (tobi/try): ruby script + its lib/, kept in ~/.local/share/try
  local tdir="$HOME/.local/share/try"
  if [ -d "$tdir/.git" ]; then
    ok "try"
  elif has git; then
    step "installing try → $(pretty "$tdir")"
    run git clone -q --depth 1 https://github.com/tobi/try "$tdir" && run chmod +x "$tdir/try.rb"
  fi
  [ -d "$tdir" ] && link "$tdir/try.rb" "$HOME/.local/bin/try"
  run mkdir -p "$HOME/Work/tries"
  return 0
}

tools_doctor() {
  header "Tools"
  local f="$OMAC_CONFIG_HOME/starship.toml"
  check_file "$f" tools_seed "starship config"
  if has starship && [ -f "$f" ]; then
    local se
    se="$(STARSHIP_CONFIG="$f" starship prompt 2>&1 >/dev/null | grep -i -E 'error|unknown|invalid' | head -n 2)"
    [ -n "$se" ] && problem "starship config: $se" "" fail || pass "starship config parses"
  fi
  check_file "$OMAC_CONFIG_HOME/lazygit/config.yml" tools_seed "lazygit config"
  [ -n "${LG_CONFIG_FILE:-}" ] || note "LG_CONFIG_FILE unset in this shell; lazygit reads ~/Library/Application Support until you open a new terminal"
  check_file "$OMAC_CONFIG_HOME/btop/btop.conf" tools_seed "btop config"
  if has try; then pass "try"; else problem "try not installed" tools_seed; fi
  check_duplicates nvim git starship fzf tmux herdr lazygit rg
}
fix_tools_seed() { tools_install; }

# ── terminal: Ghostty ─────────────────────────────────────────────────────────
terminal_desc() { echo "Ghostty config with Omarchy keybinds (option-as-alt, CSI-u Shift+Enter)"; }

terminal_install() {
  header "Ghostty"
  local dir="$OMAC_CONFIG_HOME/ghostty"
  seed "$OMAC_PATH/config/ghostty/config.ghostty" "$dir/config.ghostty"
  # Ghostty loads both `config` and `config.ghostty`; a stray `config` silently overrides ours
  if [ -f "$dir/config" ] && ! is_seeded "$dir/config"; then
    if [ ! -s "$dir/config" ]; then
      run rm -f "$dir/config"; ok "removed empty ~/.config/ghostty/config (it shadowed config.ghostty)"
    else
      warn "~/.config/ghostty/config also exists and is loaded too; run 'omac fix' to fold it away"
    fi
  fi
  return 0
}

terminal_doctor() {
  header "Ghostty"
  local dir="$OMAC_CONFIG_HOME/ghostty" g
  g="$(ghostty_bin)"
  if [ -n "$g" ]; then pass "Ghostty installed"; else problem "Ghostty not installed" brew_bundle fail; fi
  check_file "$dir/config.ghostty" terminal_seed "Ghostty config"
  [ -f "$dir/config" ] && [ -f "$dir/config.ghostty" ] && problem "both ~/.config/ghostty/config and config.ghostty exist; Ghostty loads both" ghostty_dup
  local mac="$HOME/Library/Application Support/com.mitchellh.ghostty"
  { [ -s "$mac/config" ] || [ -s "$mac/config.ghostty" ]; } && problem "Ghostty also loads a config from ~/Library/Application Support/com.mitchellh.ghostty, which overrides ~/.config" ghostty_dup
  if [ -n "$g" ] && [ -f "$dir/config.ghostty" ]; then
    local out
    out="$("$g" +validate-config 2>&1)"
    if [ -n "$out" ]; then problem "Ghostty config errors: $(printf '%s' "$out" | head -n 3 | tr '\n' ' ')" "" fail; else pass "Ghostty config is valid"; fi
    grep -qs 'macos-option-as-alt' "$dir/config.ghostty" || problem "macos-option-as-alt not set: herdr/tmux Alt bindings won't work" terminal_seed
  fi
  if ls "$HOME/Library/Fonts" /Library/Fonts 2>/dev/null | grep -qi 'JetBrainsMonoNerd'; then pass "JetBrainsMono Nerd Font"
  else problem "JetBrainsMono Nerd Font not installed (Ghostty falls back to its bundled font; other terminals lose icons)" brew_bundle; fi
}
fix_terminal_seed() { OMAC_CONFLICT=replace terminal_install; }
fix_ghostty_dup() {
  local f
  for f in "$OMAC_CONFIG_HOME/ghostty/config" "$HOME/Library/Application Support/com.mitchellh.ghostty/config" "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"; do
    [ -f "$f" ] || continue
    is_seeded "$f" && continue
    backup_path "$f"
  done
  info "moved the extra Ghostty configs to the backup folder; copy anything you miss into ~/.config/ghostty/config.ghostty"
}

# ── herdr ─────────────────────────────────────────────────────────────────────
herdr_desc() { echo "herdr with Omarchy's tmux-style keys + the omac theme"; }

herdr_install() {
  header "herdr"
  seed "$OMAC_PATH/config/herdr/config.toml" "$OMAC_CONFIG_HOME/herdr/config.toml"
}

herdr_doctor() {
  header "herdr"
  if ! has herdr; then problem "herdr not installed" brew_bundle fail; return; fi
  pass "herdr $(herdr --version 2>/dev/null | awk '{print $2}') at $(pretty "$(command -v herdr)")"
  local f="$OMAC_CONFIG_HOME/herdr/config.toml"
  check_file "$f" herdr_seed "herdr config"
  if [ -f "$f" ]; then
    local out
    out="$(herdr config check 2>&1)"; local rc=$?
    if [ $rc -ne 0 ] || printf '%s' "$out" | grep -qiE 'error|invalid|unknown'; then
      problem "herdr config check: $(printf '%s' "$out" | head -n 3 | tr '\n' ' ')" "" fail
    else pass "herdr config check passes"; fi
    grep -q '^prefix = "ctrl+space"' "$f" || note "herdr prefix isn't Omarchy's ctrl+space"
    grep -q '^\[theme\]' "$f" || problem "herdr config has no omac [theme]" theme
    grep -qE '"ctrl\+alt\+(shift\+)?(left|right|up|down)"' "$f" && problem "herdr uses Ctrl+Option+arrows, which Raycast window management takes first" pane_keys
  fi
  # macOS: Ctrl+Space is "select previous input source" by default and eats herdr/tmux's prefix
  local hk
  hk="$(defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys 2>/dev/null | awk '/^ *60 = /{f=1} f&&/enabled/{print; exit}')"
  case "$hk" in *"enabled = 1"*) problem "macOS uses Ctrl+Space to switch input source, which steals the herdr/tmux prefix" ctrl_space ;; esac
}
fix_herdr_seed() { herdr_install; theme_apply "$(theme_current)"; }
fix_ctrl_space() {
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 "<dict><key>enabled</key><false/></dict>"
  /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2>/dev/null || true
  ok "disabled macOS Ctrl+Space input-source shortcut (log out/in if it still triggers)"
}

# ── tmux ──────────────────────────────────────────────────────────────────────
tmux_desc() { echo "Omarchy's tmux.conf (C-Space prefix, Alt bindings) + the omac theme"; }

tmux_install() {
  header "tmux"
  seed "$OMAC_PATH/config/tmux/tmux.conf" "$OMAC_CONFIG_HOME/tmux/tmux.conf"
  [ -f "$HOME/.tmux.conf" ] && warn "~/.tmux.conf exists; tmux reads it instead of ~/.config/tmux/tmux.conf (omac fix moves it away)"
  return 0
}

tmux_doctor() {
  header "tmux"
  has tmux || { problem "tmux not installed" brew_bundle fail; return; }
  local f="$OMAC_CONFIG_HOME/tmux/tmux.conf"
  check_file "$f" tmux_seed "tmux config"
  [ -f "$HOME/.tmux.conf" ] && problem "~/.tmux.conf shadows ~/.config/tmux/tmux.conf" tmux_dotfile
  if [ -f "$f" ]; then
    local out
    out="$(tmux -S "/tmp/omac-doctor-$$" -f /dev/null start-server \; source-file "$f" \; kill-server 2>&1)"; rm -f "/tmp/omac-doctor-$$"
    if [ -n "$out" ]; then problem "tmux config errors: $(printf '%s' "$out" | head -n 2 | tr '\n' ' ')" "" fail; else pass "tmux config loads cleanly"; fi
    grep -qE '^[^#]*bind -n C-M-(S-)?(Left|Right|Up|Down)' "$f" && problem "tmux uses Ctrl+Option+arrows, which Raycast window management takes first" pane_keys
  fi
}
fix_tmux_seed() { tmux_install; }

# Move herdr/tmux pane keys off Ctrl+Option (Raycast window management) onto Ctrl+Shift
fix_pane_keys() {
  local f="$OMAC_CONFIG_HOME/herdr/config.toml" d
  if [ -f "$f" ] && grep -qE '"ctrl\+alt\+(shift\+)?(left|right|up|down)"' "$f"; then
    backup_copy "$f"
    for d in left right up down; do
      sed -i '' -E "s/^focus_pane_$d = .*/focus_pane_$d = [\"ctrl+shift+$d\", \"prefix+$d\"]/" "$f"
      sed -i '' -E "/^resize_pane_$d = \"ctrl\+alt\+shift\+$d\"/d" "$f"
    done
    herdr server reload-config >/dev/null 2>&1 || true
    ok "herdr: panes on Ctrl+Shift+arrows, resize with prefix+ctrl+arrows"
  fi
  f="$OMAC_CONFIG_HOME/tmux/tmux.conf"
  if [ -f "$f" ] && grep -qE '^[^#]*bind -n C-M-(S-)?(Left|Right|Up|Down)' "$f"; then
    backup_copy "$f"
    sed -i '' -E 's/^bind -n C-M-(Left|Right|Up|Down) select-pane/bind -n C-S-\1 select-pane/; s/^bind -n C-M-S-(Left|Right|Up|Down) resize-pane/bind -r C-\1 resize-pane/' "$f"
    tmux source-file "$f" >/dev/null 2>&1 || true
    ok "tmux: panes on Ctrl+Shift+arrows, resize with prefix+ctrl+arrows"
  fi
}
fix_tmux_dotfile() { backup_path "$HOME/.tmux.conf"; }

# ── nvim ──────────────────────────────────────────────────────────────────────
nvim_desc() { echo "Neovim: Omarchy's LazyVim setup with the omac theme's colorscheme"; }

nvim_install() {
  header "Neovim"
  seed "$OMAC_PATH/config/nvim" "$OMAC_CONFIG_HOME/nvim"
  if has nvim && [ "$OMAC_DRY_RUN" != 1 ] && is_seeded "$OMAC_CONFIG_HOME/nvim"; then
    step "installing LazyVim plugins (headless)"
    nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1 && ok "plugins synced" || warn "plugin sync had errors; open nvim and run :Lazy"
  fi
  return 0
}

nvim_doctor() {
  header "Neovim"
  has nvim || { problem "neovim not installed" brew_bundle fail; return; }
  pass "$(nvim --version | head -n1)"
  local d="$OMAC_CONFIG_HOME/nvim"
  check_file "$d/init.lua" nvim_seed "Neovim config"
  if is_seeded "$d"; then pass "Neovim config is omac's LazyVim"
  elif [ -d "$d" ]; then note "~/.config/nvim is your own config (omac's LazyVim: omac refresh nvim)"; fi
  if [ -f "$d/init.lua" ]; then
    local out
    out="$(with_timeout 30 nvim --headless "+lua vim.defer_fn(function() vim.cmd('qa!') end, 1500)" 2>&1 | grep -iE '^E[0-9]+|error' | head -n 3)"
    [ -n "$out" ] && problem "Neovim reports errors at startup: $(printf '%s' "$out" | tr '\n' ' ')" "" warn || pass "Neovim starts without errors"
  fi
  has tree-sitter || problem "tree-sitter CLI missing (LazyVim builds parsers with it)" brew_bundle
  has rg && has fd || problem "rg/fd missing (LazyVim pickers need them)" brew_bundle
}
fix_nvim_seed() { nvim_install; }
