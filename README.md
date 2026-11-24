# omac: Omarchy for macOS

Omarchy's CLI tools, shell functions, keybindings, and configs, set up on a Mac by one command. It includes a manager (`omac`) that finds problems and conflicts and fixes them.

On a fresh Mac:

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Yolooo332/omac/main/install.sh)"
```

From a checkout:

```sh
./install.sh                 # everything (asks before replacing any config of yours)
omac doctor                  # check for problems and conflicts
omac fix                     # repair them
omac theme tokyo-night       # any Omarchy theme, or Baby Blue (white|dark)
omac keys                    # cheat sheet (also Super+K)
```

## What gets installed

| Module | What |
|---|---|
| `brew` | Xcode CLT, Homebrew, Omarchy's base CLI tools (`packages/Brewfile`) |
| `shell` | zsh with Omarchy's aliases and functions ported from bash (`default/zsh/`). `~/.zshrc` sources them |
| `git` | Omarchy git defaults in `~/.config/git/config`. Your name and email stay in `~/.gitconfig` |
| `mise` | Omarchy's lazy tools and AI agents (claude, codex, opencode, gemini, ...) in `~/.config/mise/conf.d/omac.toml` |
| `tools` | starship, lazygit, btop, [try](https://github.com/tobi/try) |
| `terminal` | Ghostty with Omarchy's keybinds (Option acts as Alt, Shift+Enter sent as CSI-u, quick terminal) |
| `herdr` | herdr with Omarchy's tmux-style keys and the omac theme |
| `tmux` | Omarchy's tmux.conf (Ctrl+Space prefix) |
| `nvim` | Omarchy's LazyVim with the omac theme's colorscheme |
| `wm` | Raycast: window management, launcher and clipboard history (no tiling manager), plus omac script commands to bind hotkeys to |
| `vscode` | Baby Blue Theme `.vsix` |
| `theme` | Baby Blue **white** (default) or dark, or any of Omarchy's 23 themes, applied to every app above |
| `apps` *(optional)* | Omarchy's default GUI apps: Chrome, 1Password, Obsidian, LocalSend, Signal, Spotify, IINA ... |
| `extra` *(optional)* | other apps from the Omarchy machine: Helix, Typora, OBS, Steam, Wireshark ... |
| `macos` *(optional)* | defaults that make macOS feel like Omarchy: fast key repeat, Ctrl+Cmd+drag, Dock autohide |

```sh
omac install                    # default modules
omac install apps macos         # optional ones
omac install --skip wm,vscode   # leave some out
omac install --dry-run          # show what would happen
```

## How it's laid out (same model as Omarchy)

- **Defaults live in the repo** and are sourced, so `omac update` (git pull) brings changes: `default/zsh/*`, the themes, the omac CLI. The repo is linked at `~/.local/share/omac`.
- **Your configs are seeded once.** omac copies `config/*` into `~/.config` and marks the copy `omac:seeded`. After that the file is yours to edit. `omac refresh <name>` resets it to the default and keeps a backup.
- **The theme is state.** `omac theme` writes `~/.local/state/omac/theme/`, which Ghostty, tmux, zsh and Neovim include. For apps that can't include files (herdr, starship, btop, lazygit), omac rewrites only their theme section in place.

## Conflicts and fixes

omac never overwrites a file it didn't create without asking. For each one it offers **[r]eplace** (the old file is backed up), **[s]kip**, or **[d]iff**. `--replace` and `--keep` give the same answer for every file. Backups go to `~/.local/state/omac/backups/<timestamp>/`. To list and restore them: `omac backups`, then `omac restore <id> [path]`.

When you replace an old `~/.zshrc`, its machine-specific `export`/`source` lines move into `~/.zshrc.local`. Lines omac already covers are left out: starship, zoxide, fzf, mise, and the zsh plugins.

`omac doctor` checks:

- Homebrew and the CLT are present, core packages are installed, and `brew doctor` is clean
- the same tool isn't installed twice (`claude` from npm and from mise, `herdr` from its installer and from brew). It also reports which copy wins on PATH
- `.zshrc` loads omac, no tool is initialized twice, no rc file sources a missing file, there are no oh-my-zsh clashes, completion dirs are secure, startup time, broken symlinks in `~/.config`
- each config is valid according to its own program: `ghostty +validate-config`, `herdr config check`, tmux, starship, `nvim --headless`
- shadowing files: `~/.tmux.conf`, a second Ghostty `config` next to `config.ghostty`, or a Ghostty config in `~/Library/Application Support`
- macOS's Ctrl+Space input-source shortcut, which takes the herdr/tmux prefix
- other window tools running next to Raycast window management (AeroSpace, Rectangle, Magnet, yabai, ...)
- every app is on the same theme

`omac fix` applies the fixes it can, asking before each one (`--yes` applies them all).

If a tool is already installed in your home folder (by herdr's or mise's own installer, for example), omac keeps that copy and doesn't add a Homebrew duplicate. If a GUI app is already in /Applications, Homebrew adopts it (`--adopt`) so the install doesn't fail.

## Keybindings

There's no tiling manager and there are no workspace hotkeys. **Raycast Window Management on Ctrl+Option** moves and resizes windows: Ctrl+Option+Return for almost full screen with 8 px padding, Ctrl+Option+C to center, and you switch Spaces with a trackpad swipe. Ctrl+Option belongs to Raycast, so herdr and tmux move between panes with **Ctrl+Shift+arrows** (Omarchy uses Ctrl+Alt+arrows) and resize with Prefix + Ctrl+arrows. `omac doctor` warns when an older herdr or tmux config still uses Ctrl+Alt+arrows, and `omac fix` moves those keys.

Raycast keeps its hotkeys in its own settings, which omac can't write. omac ships Raycast script commands in `raycast/`: terminal with herdr or tmux, Neovim, btop, lazydocker, and omac menu, keys, theme, doctor, fix and update. Add that folder to Raycast once (Settings → Extensions → + → Add Script Directory → `~/.local/share/omac/raycast`). `docs/KEYBINDINGS.md` lists the Ctrl+Option window layout and suggested hotkeys for the scripts.

## Themes

```sh
omac theme list              # every theme (* = current)
omac theme pick              # fuzzy picker (needs gum); also in omac menu and Raycast
omac theme tokyo-night       # "Tokyo Night" works too
omac theme white             # back to Baby Blue White (dark = Baby Blue Dark)
```

Two families switch the same set of apps: Ghostty, tmux, herdr (CLI and app), starship, btop, lazygit, fzf and Neovim.

- **Baby Blue** (`white`, `dark`): omac's own theme. `themes/baby-blue/` is a vendored copy of the Baby Blue theme repo, with `palette.json` as the source of truth. omac adds tmux, lazygit and fzf ports through `themes/omac-ports.py`. If you edit the palette, re-run that script and `node themes/baby-blue/scripts/build.mjs`, then `omac theme white`.
- **Omarchy** (`catppuccin`, `tokyo-night`, `gruvbox`, `nord`, `rose-pine`, ...): every stock Omarchy theme, generated into `themes/omarchy/<name>/` from Omarchy's `colors.toml` by `themes/omarchy-themes.py`. Ghostty, btop and Neovim use Omarchy's own templates, and a theme's own `btop.theme` and `neovim.lua` win when it ships them. Omarchy's `white` theme is called `omarchy-white` here, because `white` means Baby Blue White. To pull in newer Omarchy themes, clone [Omarchy](https://github.com/basecamp/omarchy) and run `python3 -I themes/omarchy-themes.py path/to/omarchy`.

Neovim switches on its next start (it installs the theme's plugin the first time). For VS Code, `omac theme` prints the extension to install. Wallpapers, Hyprland, Waybar and the other Linux-desktop parts of Omarchy themes don't apply on macOS.

## Credits

[Omarchy](https://github.com/basecamp/omarchy) by DHH and contributors, MIT licensed: omac ports its configs, shell functions, keybindings and themes to macOS. The files in `themes/omarchy/` come from Omarchy's themes. See `NOTICE.md`.

## License

MIT, see `LICENSE`. Third-party notices are in `NOTICE.md`.
