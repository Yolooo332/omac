# shell: zsh with Omarchy's aliases/functions, the omac command on PATH

shell_desc() { echo "zsh config (~/.zshrc → omac defaults), omac on PATH"; }

OMAC_HOME_LINK="$HOME/.local/share/omac"

# Pull machine-specific PATH/export lines out of an old ~/.zshrc into ~/.zshrc.local,
# skipping everything the omac defaults already do.
migrate_zshrc() {
  local old="$1" local_rc="$HOME/.zshrc.local" lines
  [ -f "$old" ] || return 0
  [ -e "$local_rc" ] && { info "~/.zshrc.local exists; not migrating"; return 0; }
  lines="$(grep -E '^[[:space:]]*(export|source|\.|eval|alias|path\+?=)' "$old" \
    | grep -vE 'starship init|zoxide init|mise activate|fzf --zsh|zsh-autosuggestions|zsh-syntax-highlighting|zsh-history-substring-search|baby-blue-theme|FZF_|compinit|OMAC_PATH|default/zsh/rc' \
    | grep -vE "^[[:space:]]*export PATH=\"?\\\$HOME/\.local/bin:\\\$PATH\"?$")"
  [ -n "$lines" ] || return 0
  if [ "$OMAC_DRY_RUN" = 1 ]; then
    info "[dry-run] would move $(printf '%s\n' "$lines" | wc -l | tr -d ' ') line(s) from your old ~/.zshrc into ~/.zshrc.local"
    return 0
  fi
  {
    printf '# Migrated by omac from your previous ~/.zshrc on %s.\n' "$(date)"
    printf '# The full old file is in %s\n\n' "$(pretty "$OMAC_BACKUPS/$OMAC_RUN_ID/.zshrc")"
    printf '%s\n' "$lines"
  } >"$local_rc"
  ok "kept $(printf '%s\n' "$lines" | wc -l | tr -d ' ') machine-specific line(s) from your old ~/.zshrc in ~/.zshrc.local"
}

shell_install() {
  header "Shell"
  # Canonical location every config refers to
  if [ "$(resolve_link "$OMAC_HOME_LINK")" != "$(resolve_link "$OMAC_PATH")" ]; then
    link "$OMAC_PATH" "$OMAC_HOME_LINK"
  else
    ok "omac lives at $(pretty "$OMAC_HOME_LINK")"
  fi
  link "$OMAC_PATH/bin/omac" "$HOME/.local/bin/omac"

  local z="$HOME/.zshrc"
  if [ -f "$z" ] && ! is_seeded "$z"; then
    if resolve_conflict "$z" "$OMAC_PATH/config/zshrc"; then
      [ "$OMAC_DRY_RUN" = 1 ] || cp "$z" "$z.omac-migrate"
      seed "$OMAC_PATH/config/zshrc" "$z" 1
      migrate_zshrc "$z.omac-migrate"
      rm -f "$z.omac-migrate"
    fi
  else
    seed "$OMAC_PATH/config/zshrc" "$z"
  fi

  if [ "$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')" != /bin/zsh ] && [ "${SHELL:-}" != /bin/zsh ]; then
    warn "your login shell isn't zsh; switch with: chsh -s /bin/zsh"
  fi
}

shell_doctor() {
  header "Shell"
  if [ "$(resolve_link "$OMAC_HOME_LINK")" = "$(resolve_link "$OMAC_PATH")" ]; then pass "omac at $(pretty "$OMAC_HOME_LINK")"
  else problem "$(pretty "$OMAC_HOME_LINK") doesn't point at this checkout ($(pretty "$OMAC_PATH"))" omac_link fail; fi

  if [ "$(resolve_link "$HOME/.local/bin/omac")" = "$(resolve_link "$OMAC_PATH/bin/omac")" ]; then pass "omac command on PATH"
  else problem "~/.local/bin/omac missing or points elsewhere" omac_link; fi

  local z="$HOME/.zshrc"
  if grep -qs 'default/zsh/rc' "$z"; then pass "~/.zshrc loads the omac defaults"
  else problem "~/.zshrc doesn't source omac's defaults (aliases, functions, prompt)" zshrc fail; fi

  # The same tool initialized twice (old lines left behind) slows startup and fights over keybindings
  local files="" f pat n
  for f in "$HOME/.zshrc" "$HOME/.zshrc.local" "$HOME/.zprofile" "$HOME/.zshenv"; do [ -f "$f" ] && files="$files $f"; done
  if [ -n "$files" ] && grep -qs 'default/zsh/rc' "$z"; then
    for pat in 'starship init' 'zoxide init' 'mise activate' 'fzf --zsh' 'zsh-syntax-highlighting.zsh' 'zsh-autosuggestions.zsh' 'compinit'; do
      # shellcheck disable=SC2086
      n="$(grep -hE "^[^#]*$pat" $files 2>/dev/null | wc -l | tr -d ' ')"
      [ "$n" -gt 0 ] && problem "'$pat' runs again outside omac (omac already does it): $(grep -lE "^[^#]*$pat" $files | while read -r x; do pretty "$x"; printf ' '; done)" dup_init
    done
  fi

  # Files sourced from rc files that no longer exist
  local line p
  for f in $files; do
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      p="$(printf '%s' "$line" | awk '{print $2}' | tr -d '"'"'" | sed "s#^~#$HOME#; s#\$HOME#$HOME#; s#\${HOME}#$HOME#")"
      case "$p" in *'$'*|*'('*|'<'*|'') continue ;; esac
      [ -e "$p" ] || problem "$(pretty "$f") sources a missing file: $(pretty "$p")" "" warn
    done <<SRC
$(grep -hE '^[[:space:]]*(source|\.)[[:space:]]+' "$f" 2>/dev/null)
SRC
  done

  [ -d "$HOME/.oh-my-zsh" ] && grep -qs 'oh-my-zsh.sh' $files && problem "oh-my-zsh is also loaded; it overrides omac's prompt, completion and aliases" "" warn

  if has zsh; then
    local insecure
    insecure="$(zsh -c 'autoload -Uz compaudit; compaudit 2>/dev/null')"
    if [ -n "$insecure" ]; then problem "insecure completion dirs (group/world-writable): $(printf '%s' "$insecure" | tr '\n' ' ')" compaudit
    else pass "completion dirs are secure"; fi

    local t0 t1 ms
    t0="$(perl -MTime::HiRes=time -e 'printf "%d", time*1000')"
    zsh -i -c exit >/dev/null 2>&1 </dev/null
    t1="$(perl -MTime::HiRes=time -e 'printf "%d", time*1000')"
    ms=$((t1 - t0))
    if [ "$ms" -gt 800 ]; then problem "zsh takes ${ms}ms to start (try: zsh -xi -c exit 2>&1 | less)" "" warn
    else pass "zsh starts in ${ms}ms"; fi
  fi

  # Broken symlinks in ~/.config
  local broken
  broken="$(find "$OMAC_CONFIG_HOME" -maxdepth 2 -type l ! -exec test -e {} \; -print 2>/dev/null)"
  if [ -n "$broken" ]; then problem "broken symlinks: $(printf '%s\n' "$broken" | while read -r x; do pretty "$x"; printf ' '; done)" broken_links
  else pass "no broken symlinks in ~/.config"; fi
}

fix_omac_link() { link "$OMAC_PATH" "$OMAC_HOME_LINK"; link "$OMAC_PATH/bin/omac" "$HOME/.local/bin/omac"; }
fix_zshrc() { OMAC_CONFLICT=replace shell_install; }
fix_dup_init() {
  local f
  for f in "$HOME/.zshrc" "$HOME/.zshrc.local" "$HOME/.zprofile" "$HOME/.zshenv"; do
    [ -f "$f" ] || continue
    grep -qE '^[^#]*(starship init|zoxide init|mise activate|fzf --zsh|zsh-syntax-highlighting.zsh|zsh-autosuggestions.zsh|compinit)' "$f" || continue
    backup_copy "$f"
    # Comment the duplicates out rather than deleting them
    sed -i '' -E 's/^([^#]*(starship init|zoxide init|mise activate|fzf --zsh|zsh-syntax-highlighting\.zsh|zsh-autosuggestions\.zsh|compinit).*)$/# [omac: done by omac defaults] \1/' "$f"
    ok "commented duplicate init lines in $(pretty "$f")"
  done
}
fix_compaudit() {
  zsh -c 'autoload -Uz compaudit; compaudit 2>/dev/null' | while IFS= read -r d; do chmod g-w,o-w "$d" && ok "secured $d"; done
}
fix_broken_links() {
  find "$OMAC_CONFIG_HOME" -maxdepth 2 -type l ! -exec test -e {} \; -print 2>/dev/null | while IFS= read -r l; do
    backup_path "$l"
  done
}
