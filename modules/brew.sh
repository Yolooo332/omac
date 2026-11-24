# brew: Xcode CLT + Homebrew + the core Brewfile (Omarchy's base CLI tools)

brew_desc() { echo "Homebrew and the core CLI tools (packages/Brewfile)"; }

# Command a formula provides, for spotting copies installed outside Homebrew.
formula_cmd() {
  case "$1" in
    tlrc) echo tldr ;; ripgrep) echo rg ;; neovim) echo nvim ;; tree-sitter-cli) echo tree-sitter ;;
    zsh-*|font-*|imagemagick|tesseract|zbar|qrencode|usage|lua|luarocks|ruby|rsync|wget|whois|socat) echo "" ;;
    *) echo "${1##*/}" ;;
  esac
}

_brew_installed_formulae=""
_brew_installed_casks=""
brew_refresh_lists() {
  _brew_installed_formulae="$(brew list --formula -1 2>/dev/null)"
  _brew_installed_casks="$(brew list --cask -1 2>/dev/null)"
}
brew_has_formula() { printf '%s\n' "$_brew_installed_formulae" | grep -qx "${1##*/}"; }
brew_has_cask() { printf '%s\n' "$_brew_installed_casks" | grep -qx "${1##*/}"; }

# Read "brew|cask|tap name" entries from a Brewfile.
brewfile_entries() {
  sed -nE 's/^[[:space:]]*(tap|brew|cask)[[:space:]]+"([^"]+)".*/\1 \2/p' "$1"
}

# A command the user installed into $HOME (self-updating installers like herdr's
# or mise's) wins over a Homebrew duplicate.
home_installed() {
  local cmd="$1" p
  [ -n "$cmd" ] || return 1
  p="$(type -ap "$cmd" 2>/dev/null | head -n1)"
  case "$p" in "$HOME"/*) printf '%s' "$p"; return 0 ;; esac
  return 1
}

# Install every entry of a Brewfile, skipping what's there and handling conflicts.
brewfile_install() {
  local file="$1" kind name cmd p failed=""
  ensure_brew_env
  has brew || { err "Homebrew is not installed"; return 1; }
  brew_refresh_lists
  while read -r kind name; do
    [ -n "$name" ] || continue
    case "$kind" in
      tap)
        brew tap | grep -qix "$name" && continue
        run brew tap "$name" && ok "tap $name"
        ;;
      brew)
        if brew_has_formula "$name"; then ok "$name"; continue; fi
        cmd="$(formula_cmd "$name")"
        if p="$(home_installed "$cmd")"; then
          ok "$name: keeping your own install at $(pretty "$p") (not installing a Homebrew duplicate)"
          continue
        fi
        step "brew install $name"
        run brew install "$name" || failed="$failed $name"
        ;;
      cask)
        if brew_has_cask "$name"; then ok "$name"; continue; fi
        step "brew install --cask $name"
        # --adopt takes over an app you installed by hand instead of failing on it
        if ! run brew install --cask --adopt "$name"; then
          warn "$name: couldn't install or adopt (an existing copy may be a different version). Leaving it as is."
          failed="$failed $name"
        fi
        ;;
    esac
  done <<EOF
$(brewfile_entries "$file")
EOF
  [ -z "$failed" ] || warn "not installed:$failed"
  return 0
}

brewfile_missing() {
  local file="$1" kind name cmd out=""
  brew_refresh_lists
  while read -r kind name; do
    case "$kind" in
      brew) brew_has_formula "$name" && continue; cmd="$(formula_cmd "$name")"; home_installed "$cmd" >/dev/null && continue; out="$out $name" ;;
      cask) brew_has_cask "$name" || out="$out $name" ;;
    esac
  done <<EOF
$(brewfile_entries "$file")
EOF
  printf '%s' "${out# }"
}

brew_install() {
  header "Homebrew"
  if ! xcode-select -p >/dev/null 2>&1; then
    step "Installing Xcode Command Line Tools (a dialog will open; re-run omac when it finishes)"
    run xcode-select --install || true
    return 1
  fi
  ok "Xcode Command Line Tools"

  ensure_brew_env
  if ! has brew; then
    step "Installing Homebrew"
    run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ensure_brew_env
  fi
  ok "Homebrew $(brew --version 2>/dev/null | head -n1 | awk '{print $2}')"

  # Login shells need brew on PATH
  if ! grep -qs 'brew shellenv' "$HOME/.zprofile"; then
    [ "$OMAC_DRY_RUN" = 1 ] || printf '\neval "$(%s/bin/brew shellenv zsh)"\n' "$(brew_prefix)" >>"$HOME/.zprofile"
    ok "added brew shellenv to ~/.zprofile"
  fi

  brewfile_install "$OMAC_PATH/packages/Brewfile"
}

brew_doctor() {
  header "Homebrew"
  if xcode-select -p >/dev/null 2>&1; then pass "Xcode Command Line Tools"; else problem "Xcode Command Line Tools missing" clt fail; fi
  ensure_brew_env
  if ! has brew; then problem "Homebrew not installed" brew fail; return; fi
  pass "Homebrew at $(brew_prefix)"
  grep -qs 'brew shellenv' "$HOME/.zprofile" || problem "~/.zprofile doesn't put Homebrew on PATH for login shells" zprofile
  local missing
  missing="$(brewfile_missing "$OMAC_PATH/packages/Brewfile")"
  if [ -z "$missing" ]; then pass "all core packages installed"; else problem "missing core packages: $missing" brew_bundle; fi
  # brew doctor is slow and chatty; summarize only its warning titles
  local bd
  bd="$(brew doctor 2>&1 | grep -E '^Warning:' | sed 's/^Warning: //' | head -n 5)"
  if [ -n "$bd" ]; then
    while IFS= read -r l; do problem "brew doctor: $l" "" warn; done <<BD
$bd
BD
  else
    pass "brew doctor is clean"
  fi
}

fix_clt() { xcode-select --install || true; }
fix_brew() { brew_install; }
fix_zprofile() { printf '\neval "$(%s/bin/brew shellenv zsh)"\n' "$(brew_prefix)" >>"$HOME/.zprofile"; ok "added brew shellenv to ~/.zprofile"; }
fix_brew_bundle() { brewfile_install "$OMAC_PATH/packages/Brewfile"; }
