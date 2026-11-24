# omac shared helpers. Sourced by bin/omac and every module.
# Must stay compatible with macOS /bin/bash 3.2: no associative arrays,
# no mapfile, no ${var,,}, no negative array indexes.

OMAC_STATE="${OMAC_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/omac}"
OMAC_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
OMAC_THEME_DIR="$OMAC_STATE/theme"
OMAC_BACKUPS="$OMAC_STATE/backups"
OMAC_SETTINGS="$OMAC_STATE/settings"
OMAC_RUN_ID="${OMAC_RUN_ID:-$(date +%Y%m%d-%H%M%S)}"

# Behaviour switches (set by bin/omac flags)
OMAC_YES="${OMAC_YES:-0}"          # 1 = answer yes to every prompt
OMAC_DRY_RUN="${OMAC_DRY_RUN:-0}"  # 1 = print what would happen, change nothing
OMAC_CONFLICT="${OMAC_CONFLICT:-ask}" # ask | replace | skip  (what to do with a file omac does not own)

# ── output ────────────────────────────────────────────────────────────────────
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  # Baby Blue: accent #89CFF0 for headings, green/orange/red for status.
  C_ACC=$'\033[1;38;2;22;119;168m'
  C_FILL=$'\033[38;2;137;207;240m'
  C_OK=$'\033[38;2;68;130;25m'
  C_WARN=$'\033[38;2;194;94;0m'
  C_ERR=$'\033[38;2;207;58;58m'
  C_DIM=$'\033[2m'
  C_B=$'\033[1m'
  C_0=$'\033[0m'
else
  C_ACC= C_FILL= C_OK= C_WARN= C_ERR= C_DIM= C_B= C_0=
fi

say()     { printf '%s\n' "$*"; }
header()  { printf '\n%s━━ %s%s\n' "$C_ACC" "$*" "$C_0"; }
step()    { printf '%s›%s %s\n' "$C_FILL" "$C_0" "$*"; }
ok()      { printf '  %s✓%s %s\n' "$C_OK" "$C_0" "$*"; }
info()    { printf '  %s·%s %s\n' "$C_DIM" "$C_0" "$*"; }
warn()    { printf '  %s!%s %s\n' "$C_WARN" "$C_0" "$*" >&2; }
err()     { printf '  %s✗%s %s\n' "$C_ERR" "$C_0" "$*" >&2; }
die()     { err "$*"; exit 1; }

# Run a command, or just print it in dry-run mode.
run() {
  if [ "$OMAC_DRY_RUN" = 1 ]; then
    printf '  %s[dry-run]%s %s\n' "$C_DIM" "$C_0" "$*"
    return 0
  fi
  "$@"
}

has() { command -v "$1" >/dev/null 2>&1; }

is_macos() { [ "$(uname -s)" = Darwin ]; }

confirm() {
  # confirm "question" [default y|n]
  local q="$1" def="${2:-n}" ans
  [ "$OMAC_YES" = 1 ] && return 0
  if [ ! -t 0 ]; then
    [ "$def" = y ]
    return
  fi
  if [ "$def" = y ]; then printf '  %s?%s %s [Y/n] ' "$C_FILL" "$C_0" "$q"; else printf '  %s?%s %s [y/N] ' "$C_FILL" "$C_0" "$q"; fi
  read -r ans </dev/tty || ans=
  [ -z "$ans" ] && ans="$def"
  case "$ans" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

# ── settings (tiny key=value store in ~/.local/state/omac/settings) ───────────
setting_get() {
  # setting_get key [default]
  local v=""
  [ -f "$OMAC_SETTINGS" ] && v="$(grep -E "^$1=" "$OMAC_SETTINGS" 2>/dev/null | tail -n1 | cut -d= -f2-)"
  [ -n "$v" ] && printf '%s' "$v" || printf '%s' "${2:-}"
}

setting_set() {
  [ "$OMAC_DRY_RUN" = 1 ] && { info "[dry-run] setting $1=$2"; return 0; }
  mkdir -p "$OMAC_STATE"
  local tmp="$OMAC_SETTINGS.tmp"
  { [ -f "$OMAC_SETTINGS" ] && grep -vE "^$1=" "$OMAC_SETTINGS"; printf '%s=%s\n' "$1" "$2"; } >"$tmp"
  mv "$tmp" "$OMAC_SETTINGS"
}

# ── paths ─────────────────────────────────────────────────────────────────────
# Path relative to $HOME for display and backup layout.
home_rel() {
  case "$1" in
    "$HOME"/*) printf '%s' "${1#"$HOME"/}" ;;
    *) printf '%s' "${1#/}" ;;
  esac
}

pretty() { case "$1" in "$HOME"/*) printf '~/%s' "${1#"$HOME"/}" ;; *) printf '%s' "$1" ;; esac; }

# Resolve a symlink chain to its final target (portable: no GNU readlink -f).
resolve_link() {
  local p="$1" t i=0
  while [ -L "$p" ] && [ $i -lt 40 ]; do
    t="$(readlink "$p")"
    case "$t" in /*) p="$t" ;; *) p="$(dirname "$p")/$t" ;; esac
    i=$((i + 1))
  done
  printf '%s' "$p"
}

# ── backups ───────────────────────────────────────────────────────────────────
# Move an existing path into this run's backup folder, keeping its layout.
backup_path() {
  local target="$1" dest
  [ -e "$target" ] || [ -L "$target" ] || return 0
  dest="$OMAC_BACKUPS/$OMAC_RUN_ID/$(home_rel "$target")"
  if [ "$OMAC_DRY_RUN" = 1 ]; then
    info "[dry-run] back up $(pretty "$target") → $(pretty "$dest")"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  mv "$target" "$dest"
  info "backed up $(pretty "$target") → $(pretty "$dest")"
}

# Copy (not move) into the backup folder: for files we patch in place.
backup_copy() {
  local target="$1" dest
  [ -e "$target" ] || return 0
  dest="$OMAC_BACKUPS/$OMAC_RUN_ID/$(home_rel "$target")"
  [ -e "$dest" ] && return 0
  [ "$OMAC_DRY_RUN" = 1 ] && return 0
  mkdir -p "$(dirname "$dest")"
  cp -R "$target" "$dest"
}

# ── ownership markers ─────────────────────────────────────────────────────────
# Seeded files carry this marker so omac can tell its own files from yours.
OMAC_MARK="omac:seeded"

is_seeded() {
  # A seeded dir has a .omac marker file; a seeded file contains the marker text.
  local p="$1"
  if [ -d "$p" ] && [ ! -L "$p" ]; then
    [ -f "$p/.omac" ]
  elif [ -f "$p" ]; then
    grep -q "$OMAC_MARK" "$p" 2>/dev/null
  else
    return 1
  fi
}

# Decide what to do with a path that exists but omac does not own.
# Returns 0 = replace it (after backup), 1 = leave it.
resolve_conflict() {
  local target="$1" src="${2:-}" ans
  case "$OMAC_CONFLICT" in
    replace) return 0 ;;
    skip) warn "kept your $(pretty "$target") (not managed by omac; --replace to take it over)"; return 1 ;;
  esac
  [ "$OMAC_YES" = 1 ] && return 0
  if [ ! -t 0 ]; then
    warn "kept your $(pretty "$target") (not managed by omac; re-run with --replace or interactively)"
    return 1
  fi
  while :; do
    printf '  %s?%s %s already exists and is not managed by omac.\n' "$C_WARN" "$C_0" "$(pretty "$target")"
    printf '    [r]eplace (backup kept)  [s]kip  [d]iff  > '
    read -r ans </dev/tty || ans=s
    case "$ans" in
      r|R) return 0 ;;
      s|S|"") warn "kept your $(pretty "$target")"; return 1 ;;
      d|D)
        if [ -n "$src" ]; then
          diff -ru "$target" "$src" | ${PAGER:-less -R} || true
        else
          info "no diff available"
        fi
        ;;
    esac
  done
}

# Short name for a seeded config path (used by `omac keep`)
config_name() {
  case "$1" in
    "$HOME/.zshrc") echo zshrc ;;
    */ghostty/*) echo ghostty ;;
    */herdr/*) echo herdr ;;
    */tmux/*) echo tmux ;;
    */nvim|*/nvim/*) echo nvim ;;
    */starship.toml) echo starship ;;
    */lazygit/*) echo lazygit ;;
    */btop/*) echo btop ;;
    */git/*) echo git ;;
    */mise/*) echo mise ;;
    *) basename "$1" ;;
  esac
}

# Configs you told omac to leave alone: omac keep starship nvim
is_kept() {
  case ",$(setting_get keep)," in *",$1,"*) return 0 ;; esac
  return 1
}

# Copy a file or directory from the repo into $HOME once ("seed"), marking it
# as omac-owned. Existing seeded copies are left alone unless force=1 (refresh).
# seed <src> <dst> [force]
seed() {
  local src="$1" dst="$2" force="${3:-0}"
  [ -e "$src" ] || { err "missing source $src"; return 1; }

  if { [ -e "$dst" ] || [ -L "$dst" ]; } && is_kept "$(config_name "$dst")"; then
    ok "$(pretty "$dst") (yours, kept: omac keep)"
    return 0
  fi

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if is_seeded "$dst" && [ "$force" != 1 ]; then
      ok "$(pretty "$dst") (already seeded)"
      return 0
    fi
    if ! is_seeded "$dst" && [ "$force" != 1 ]; then
      resolve_conflict "$dst" "$src" || return 0
    fi
    backup_path "$dst"
  fi

  if [ "$OMAC_DRY_RUN" = 1 ]; then
    info "[dry-run] seed $(pretty "$dst")"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  if [ -d "$src" ]; then
    cp -R "$src" "$dst"
    printf 'Seeded by omac from %s on %s. Delete this file to make omac treat the folder as yours.\n' "$src" "$(date)" >"$dst/.omac"
  else
    sed -e "s#@OMAC_PATH@#$OMAC_PATH#g" -e "s#@HOME@#$HOME#g" "$src" >"$dst"
    [ -x "$src" ] && chmod +x "$dst"
  fi
  ok "seeded $(pretty "$dst")"
}

# Symlink a file the user should not edit (the copy in the repo is the truth).
link() {
  local src="$1" dst="$2"
  if [ -L "$dst" ] && [ "$(resolve_link "$dst")" = "$(resolve_link "$src")" ]; then
    ok "$(pretty "$dst") → linked"
    return 0
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ -L "$dst" ] && [ ! -e "$dst" ]; then
      info "replacing broken link $(pretty "$dst")"
      run rm -f "$dst"
    else
      resolve_conflict "$dst" "$src" || return 0
      backup_path "$dst"
    fi
  fi
  run mkdir -p "$(dirname "$dst")"
  run ln -s "$src" "$dst"
  [ "$OMAC_DRY_RUN" = 1 ] || ok "linked $(pretty "$dst")"
}

# Replace a block between "# omac-theme-begin" and "# omac-theme-end" (or append).
# replace_block <file> <block-file>
replace_block() {
  local file="$1" block="$2" tmp
  [ -f "$file" ] || return 1
  [ "$OMAC_DRY_RUN" = 1 ] && { info "[dry-run] update theme block in $(pretty "$file")"; return 0; }
  tmp="$file.omac.tmp"
  awk -v blockfile="$block" '
    BEGIN { while ((getline l < blockfile) > 0) b = b l "\n"; done = 0 }
    /# omac-theme-begin/ { printf "%s", b; skip = 1; done = 1; next }
    /# omac-theme-end/ { skip = 0; next }
    !skip { print }
    END { if (!done) printf "\n%s", b }
  ' "$file" >"$tmp" && cat "$tmp" >"$file" && rm -f "$tmp"
}

# Homebrew prefix (Apple Silicon or Intel)
brew_prefix() {
  if [ -x /opt/homebrew/bin/brew ]; then printf /opt/homebrew
  elif [ -x /usr/local/bin/brew ]; then printf /usr/local
  else printf ''; fi
}

ensure_brew_env() {
  local p
  p="$(brew_prefix)"
  [ -n "$p" ] && eval "$("$p/bin/brew" shellenv)"
  case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH" ;; esac
  export PATH
}

ghostty_bin() {
  if has ghostty; then command -v ghostty
  elif [ -x /Applications/Ghostty.app/Contents/MacOS/ghostty ]; then printf /Applications/Ghostty.app/Contents/MacOS/ghostty
  fi
}

# timeout <secs> cmd... (macOS before 26 has no timeout(1))
with_timeout() {
  local s="$1"; shift
  if has timeout; then timeout "$s" "$@"
  elif has gtimeout; then gtimeout "$s" "$@"
  else perl -e 'alarm shift; exec @ARGV' "$s" "$@"; fi
}
