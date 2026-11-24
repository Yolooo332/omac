# omac keybindings

Omarchy's hotkeys, mapped to macOS. There's no tiling manager and there are no workspace hotkeys:
**windows** are moved and resized with **Raycast Window Management on Ctrl + Option**, and **Spaces** are switched with
a trackpad swipe (three or four fingers left/right, set in System Settings → Trackpad → More Gestures).

Because Ctrl + Option belongs to Raycast, herdr and tmux move between panes with **Ctrl + Shift + arrows**.
Omarchy uses Ctrl + Alt + arrows for that, but on a Mac Raycast would take those keys first.

## WM: windows (Raycast Window Management, Ctrl + Option)

Set these in Raycast → Settings → Extensions → Window Management. Keep the window **gap at 8 px** there.
That gap gives every command an 8 px margin, so Maximize becomes "almost full screen, centered":

| Hotkey | Raycast command |
|---|---|
| Ctrl + Option + Return | Maximize: almost full screen, centered, 8 px padding (with the 8 px gap) |
| Ctrl + Option + C | Center (keeps the size) |
| Ctrl + Option + ← / → | Left Half / Right Half |
| Ctrl + Option + ↑ / ↓ | Top Half / Bottom Half |
| Ctrl + Option + Backspace | Restore |
| Ctrl + Option + - / = | Make Smaller / Make Larger |
| Ctrl + Option + D / F / G | First Third / Center Third / Last Third |
| Ctrl + Option + E / T | First Two Thirds / Last Two Thirds |
| Ctrl + Option + U / I / J / K | Top Left / Top Right / Bottom Left / Bottom Right Quarter |
| Ctrl + Option + Cmd + ← / → | Previous Display / Next Display |

## Apps and omac commands (Raycast)

Add the script folder once: Raycast → Settings → Extensions → + → Add Script Directory → `~/.local/share/omac/raycast`.
Then give these hotkeys (apps: search the app in Raycast → Configure → Hotkey):

| Suggested hotkey | Raycast item | Omarchy |
|---|---|---|
| Cmd + Space | Raycast (apps, clipboard history, emoji, calculator) | Super + Space / Super + Alt + Space |
| Ctrl + Cmd + Return | Ghostty (app) | Super + Return |
| Ctrl + Cmd + Alt + Return | Terminal with herdr (script) | Super + Ctrl + Return |
| Ctrl + Cmd + Shift + Alt + Return | Terminal with tmux (script) | Super + Alt + Return |
| Ctrl + Cmd + Shift + B | browser (app) | Super + Shift + B |
| Ctrl + Cmd + Shift + N | Neovim (script) | Super + Shift + N |
| Ctrl + Cmd + Shift + T | Activity (btop) (script) | Super + Shift + T |
| Ctrl + Cmd + Shift + D | Docker (lazydocker) (script) | Super + Shift + D |
| Ctrl + Cmd + Shift + O / M / G / / | Obsidian / Spotify / Signal / 1Password | same |
| Ctrl + Cmd + Space | omac menu (script) | Super + Space menu |
| Ctrl + Cmd + K | omac keybindings (script) | Super + K |
| Ctrl + Cmd + Shift + Space | omac theme (script, pick any theme) | Super + Ctrl + T |
| — | omac doctor / omac fix / omac update (scripts) | Update menu |

Built into macOS:

| Keys | Action | Omarchy |
|---|---|---|
| Cmd + W / Cmd + Q | Close window / quit app | Super + W / Super + Q |
| Cmd + Tab | Switch app | Alt + Tab |
| Trackpad swipe left / right | Switch Space | Super + 1…9 / Super + Tab |
| Cmd + M | Minimize | Super + M |
| Ctrl + Cmd + drag | Move any window (after `omac install macos`) | Super + drag |
| Ctrl + ` | Quake terminal (Ghostty quick terminal) | Super + ` |
| Cmd + Shift + 3 / 4 / 5 | Screenshot / region / recording | Print / Alt + Print |
| Ctrl + Cmd + Q | Lock screen | Super + Esc → Lock |

## herdr

Prefix is **Ctrl + Space** (same as Omarchy). `omac doctor` warns if macOS still uses Ctrl+Space for input sources.

| Keys | Action |
|---|---|
| Alt + Return / Prefix h | Split horizontal |
| Alt + Shift + Return / Prefix v | Split vertical |
| Alt + Esc / Prefix x | Close pane |
| Ctrl + Shift + Arrows / Prefix Arrows | Focus pane (Omarchy: Ctrl + Alt + Arrows; Ctrl + Option is Raycast's on macOS) |
| Prefix Ctrl + Arrows | Resize mode |
| Prefix z | Zoom pane |
| Prefix ; | Last pane |
| Prefix c / r / k | New / rename / close tab |
| Alt + 1…9 / Prefix 1…9 | Go to tab |
| Alt + Left / Right | Previous / next tab |
| Alt + Shift + Left / Right | Move tab |
| Prefix Shift+C / Shift+R / Shift+K | New / rename / close workspace |
| Alt + Up / Down | Previous / next workspace |
| Prefix [ | Copy mode |
| Prefix q | Reload config |
| Prefix d | Detach |
| Prefix ? | Help |

Layouts: `hdl c` (editor + AI + terminal), `hdl cx c` (two AIs), `hds` (editor, diff, terminal, opencode), `hdlm c` (one tab per subfolder), `hsl 4 claude` (swarm).

## tmux

Prefix **Ctrl + Space** (or Ctrl + b). Same keys as herdr: Alt + Return splits, Alt + 1…9 windows, Ctrl + Shift + Arrows panes,
Prefix Ctrl + Arrows resize (repeatable),
Prefix c/r/k windows, Prefix C/R/K sessions, Alt + Up/Down sessions, Prefix q reload, vi copy mode (v / y).

Layouts: `tdl c`, `tds`, `tdlm c`, `tsl 4 claude`. Start: `t` (attach or new session "Work").

## nvim: Neovim (LazyVim)

| Keys | Action |
|---|---|
| Space | Leader (wait to see every binding) |
| Space Space | Find file |
| Space / | Grep |
| Space e | File explorer |
| Space , | Buffers |
| Space g g | lazygit |
| Space s g | Search with ripgrep |
| Space c a | Code action |
| Space f t | Terminal |
| g d / g r | Definition / references |
| Shift + H / L | Previous / next buffer |
| Ctrl + h/j/k/l | Move between splits |

## shell

| Command | Does |
|---|---|
| `ls` `lsa` `lt` `lta` | eza listings (tree with `lt`) |
| `ff` / `eff` | fuzzy find a file / open it in nvim |
| `sff host:/path` | fuzzy pick a file and scp it |
| `cd <partial>` | zoxide jump |
| `n` | nvim (`n` alone opens the folder) |
| `c` `cx` `cy` | opencode / Claude Code / Codex |
| `t` `h` | tmux / herdr |
| `g` `gcm` `gcam` `gcad` | git shortcuts |
| `ga <branch>` / `gd` | new worktree / remove it |
| `fip host 3000` `dip 3000` `lip` | SSH port forwards |
| `rsw src host:dst` `lsw` `dsw` | rsync-on-change watchers |
| `compress dir` `decompress f.tar.gz` | tarballs |
| `iso2sd file.iso` `format-drive disk4 Name` | write/format external drives |
| `try` | dated experiments in ~/Work/tries |
| `mup` | update mise tools |
| Ctrl + R / Ctrl + T / Alt + C | fzf history / files / cd |
| Up / Down | history search for what you typed |

## ghostty

| Keys | Action |
|---|---|
| Ctrl + ` | Quick terminal (drops from the top) |
| Shift + Enter | Newline in Claude Code / opencode (CSI-u) |
| Cmd + Shift + , | Reload config |
| Left Option | Acts as Alt (needed for herdr/tmux Alt keys) |
