# omac doctor/fix framework.
#
# Each module may define <module>_doctor. Inside it, report with:
#   pass "message"
#   problem "message" <fix-id> [warn|fail]   (fix-id names a function fix_<fix-id>)
#   note "message"                            (informational, no fix)
# `omac doctor` prints the report. `omac fix` runs the doctor, then calls each
# collected fix_<id> once (asking first unless --yes).

OMAC_FIXES=""
OMAC_N_PASS=0
OMAC_N_WARN=0
OMAC_N_FAIL=0

pass() { OMAC_N_PASS=$((OMAC_N_PASS + 1)); [ "${OMAC_QUIET_PASS:-0}" = 1 ] || ok "$1"; }
note() { info "$1"; }

problem() {
  local msg="$1" fix="${2:-}" level="${3:-warn}"
  if [ "$level" = fail ]; then
    OMAC_N_FAIL=$((OMAC_N_FAIL + 1)); err "$msg"
  else
    OMAC_N_WARN=$((OMAC_N_WARN + 1)); warn "$msg"
  fi
  if [ -n "$fix" ]; then
    printf '      %sfix:%s %s\n' "$C_DIM" "$C_0" "$fix" >&2
    case "
$OMAC_FIXES
" in
      *"
$fix
"*) ;;
      *) OMAC_FIXES="${OMAC_FIXES:+$OMAC_FIXES
}$fix" ;;
    esac
  fi
}

doctor_summary() {
  printf '\n%s%d ok%s · %s%d warning(s)%s · %s%d problem(s)%s\n' \
    "$C_OK" "$OMAC_N_PASS" "$C_0" "$C_WARN" "$OMAC_N_WARN" "$C_0" "$C_ERR" "$OMAC_N_FAIL" "$C_0"
  if [ -n "$OMAC_FIXES" ]; then
    printf 'Run %somac fix%s to repair: %s\n' "$C_B" "$C_0" "$(printf '%s' "$OMAC_FIXES" | tr '\n' ' ')"
  fi
}

run_fixes() {
  local id
  [ -n "$OMAC_FIXES" ] || { ok "nothing to fix"; return 0; }
  header "Fixing"
  printf '%s\n' "$OMAC_FIXES" | while IFS= read -r id; do
    [ -n "$id" ] || continue
    if ! type "fix_$id" >/dev/null 2>&1; then
      warn "no automatic fix for '$id' (see the doctor message above)"
      continue
    fi
    if confirm "apply fix '$id'?" y; then
      step "fix $id"
      "fix_$id" || err "fix '$id' failed"
    fi
  done
}

# ── generic checks reused by modules ──────────────────────────────────────────

# Every command found more than once on PATH, and which copy wins.
check_duplicates() {
  local cmd all first n
  for cmd in "$@"; do
    # Apple's /usr/bin stubs (git, python3...) are expected to be shadowed; don't count them
    all="$(type -ap "$cmd" 2>/dev/null | awk '!seen[$0]++' | grep -vE '^/(usr/)?s?bin/|/mise/shims/')"
    [ -n "$all" ] || continue
    # Two paths that resolve to the same file are one install.
    n="$(printf '%s\n' "$all" | while IFS= read -r p; do resolve_link "$p"; echo; done | awk 'NF' | sort -u | wc -l | tr -d ' ')"
    first="$(printf '%s\n' "$all" | head -n1)"
    if [ "$n" -gt 1 ]; then
      problem "$cmd is installed $n times; $(pretty "$first") wins. Others: $(printf '%s\n' "$all" | tail -n +2 | while IFS= read -r p; do printf '%s ' "$(pretty "$p")"; done)" "" warn
    fi
  done
}

check_file() {
  # check_file <path> <fix-id> <label>
  if [ -e "$1" ]; then pass "$3: $(pretty "$1")"; else problem "$3 missing: $(pretty "$1")" "$2" fail; fi
}
