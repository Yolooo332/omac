# Baby Blue: ls / eza / fd / completion colors.
# Uses ANSI slots only (no hex), so it follows whichever Ghostty theme is active:
#   slot 3 = baby blue (no yellow rule), 2 = green, 6 = cyan, 1 = red, 90 = grey.
# Folders: bold baby blue. Files: plain text color. Executables: bold green. Links: cyan.
# Source from ~/.zshrc:  source ~/Developer/baby-blue-theme/shell/ls-colors.zsh

# GNU-style, read by eza, fd, fzf and zsh completion
export LS_COLORS='di=1;33:fi=0:ex=1;32:ln=36:or=1;31:mi=31:so=35:pi=33:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=1;33'

# eza: start from nothing so only folders carry baby blue, then quiet grey for the long-listing columns
export EZA_COLORS='reset:di=1;33:fi=0:ex=1;32:ln=36:or=1;31:lp=36:ur=90:uw=90:ux=32:ue=32:gr=90:gw=90:gx=32:tr=90:tw=90:tx=32:xa=90:xx=90:sn=0:sb=90:uu=90:un=31:gu=90:gn=31:da=90:hd=4:ga=32:gm=34:gd=31:gv=35:gt=36:gi=90:gc=1;31'

# BSD /bin/ls (`command ls`): uppercase = bold. Dir bold slot 3, exec bold green, link cyan.
export CLICOLOR=1
export LSCOLORS='DxgxfxdxCxegedabagacad'

# Tab-completion menu uses the same colors
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

if command -v eza >/dev/null; then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza -lh --group-directories-first --icons=auto --git'
  alias la='eza -lha --group-directories-first --icons=auto --git'
  alias lt='eza --tree --level=2 --group-directories-first --icons=auto'
fi
