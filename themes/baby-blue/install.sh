#!/usr/bin/env bash
# Copies the generated Baby Blue theme files to where each app looks for them.
# Re-run after `node scripts/build.mjs`. It only adds theme files; pointing each app's
# config at them is a one-time step (see README.md).
set -euo pipefail
cd "$(dirname "$0")"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"

copy() { mkdir -p "$2"; cp "$1" "$2/"; echo "  $1 -> $2/"; }

echo "Ghostty"
copy "ghostty/themes/Baby Blue" "$CFG/ghostty/themes"
copy "ghostty/themes/Baby Blue White" "$CFG/ghostty/themes"

echo "btop"
copy btop/themes/baby-blue.theme "$CFG/btop/themes"
copy btop/themes/baby-blue-white.theme "$CFG/btop/themes"

echo "herdr app"
copy herdr-app/themes/baby-blue.json "$CFG/herdr-app/themes"
copy herdr-app/themes/baby-blue-white.json "$CFG/herdr-app/themes"

# herdr (CLI): swap the [theme] section of config.toml for ours.
# White by default; HERDR_THEME=dark or HERDR_THEME=auto (follow the terminal) for the others.
HERDR="$CFG/herdr/config.toml"
case "${HERDR_THEME:-white}" in
  white) HERDR_SRC=herdr/baby-blue.toml ;;
  dark) HERDR_SRC=herdr/baby-blue-dark.toml ;;
  auto) HERDR_SRC=herdr/baby-blue-auto.toml ;;
  *) echo "HERDR_THEME must be white, dark or auto" >&2; exit 1 ;;
esac
if [ -f "$HERDR" ]; then
  echo "herdr"
  python3 - "$HERDR" "$HERDR_SRC" <<'EOF'
import re, sys
cfg_path, theme_path = sys.argv[1], sys.argv[2]
cfg = open(cfg_path).read()
theme = open(theme_path).read().strip() + "\n"
# Drop every [theme...] table (and comments right above it), keep everything else.
out, skip = [], False
for line in cfg.splitlines(keepends=True):
    m = re.match(r"\s*\[([^\]]+)\]", line)
    if m:
        skip = m.group(1).strip().startswith("theme")
        if skip:
            while out and out[-1].lstrip().startswith("#"):
                out.pop()
    if not skip:
        out.append(line)
open(cfg_path, "w").write("".join(out).rstrip() + "\n\n" + theme)
print(f"  {theme_path} -> {cfg_path} [theme]")
EOF
fi

echo "Neovim: loaded straight from $(pwd)/nvim (lazy.nvim 'dir' spec), nothing to copy."
echo "Starship: palettes are in starship/palettes.toml (pasted into starship.toml)."
