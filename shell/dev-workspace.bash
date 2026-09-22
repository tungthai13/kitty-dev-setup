# yazi: cd to the directory you quit in (press q to cd, Q to stay)
y() {
    local tmp cwd
    tmp="$(mktemp -t yazi-cwd.XXXXXX)"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd" || return
    fi
    rm -f -- "$tmp"
}

# kdev now lives in bin/kdev (on $PATH) so yazi and scripts can call it too.

# kd: browse with yazi, quit with `q`, and open the workspace right there.
kd() {
    y "$@" && kdev
}

# zd: jump with zoxide, then open the workspace. `zd ssi` -> workspace in SSI-Backend
zd() {
    if [ $# -eq 0 ]; then
        command -v zoxide >/dev/null && { zi && kdev; }
    else
        z "$@" && kdev
    fi
}

# cdf: fuzzy-pick a directory below here and cd into it
cdf() {
    local dir
    dir="$(fd --type d --hidden --follow --exclude .git 2>/dev/null \
           | fzf --preview 'ls -la --color=always {}')" \
        && [ -n "$dir" ] && builtin cd -- "$dir"
}

# cdg: cd to the root of the current git repo
cdg() {
    local root
    root="$(git rev-parse --show-toplevel 2>/dev/null)" \
        && builtin cd -- "$root" || echo "not in a git repo" >&2
}

# e: open a file in micro, accepting Claude's path:line format
e() {
    local target="$1"
    case "$target" in
        *:[0-9]*) micro "+${target##*:}" "${target%%:*}" ;;
        *)        micro "$@" ;;
    esac
}

# --- fzf: use fd for traversal, bat for previews -----------------------
if command -v fd >/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi
if command -v bat >/dev/null; then
    export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {}'"
    export BAT_THEME="Nord"
    # man pages through bat
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi
export FZF_DEFAULT_OPTS="--height 60% --layout=reverse --border=rounded --info=inline"

# f: fuzzy-find a file and open it in $EDITOR
f() {
    local file
    file="$(fzf --preview 'bat --color=always --style=numbers --line-range=:200 {}')" \
        && [ -n "$file" ] && "${EDITOR:-micro}" "$file"
}

# lg: lazygit, then land in whatever dir it left you in
command -v lazygit >/dev/null && alias lg='lazygit'

# ---------------------------------------------------------------------
# dev -- the only command you have to remember.
# Opens a searchable menu of everything else. Type to filter, Enter to run.
# ---------------------------------------------------------------------
dev() {
    local choice key
    # format: key <TAB> label <TAB> hint
    choice="$(printf '%s\n' \
"browse	Browse files here	yazi - arrows to move, q to come back" \
"workspace	Open the 3-pane workspace here	yazi + Claude Code + shell" \
"goto	Go to another project	pick from folders you have visited" \
"goto-work	Go to another project AND open workspace	the usual way to start" \
"file	Find a file and edit it	fuzzy search, opens in micro" \
"folder	Find a folder and go there	fuzzy search below here" \
"root	Go to the top of this project	git repo root" \
"git	Open the git UI	lazygit - stage, commit, branch, diff" \
"claude	Start Claude Code here	" \
"keys	Show the keyboard shortcuts	what the key combos do" \
        | fzf --delimiter='\t' --with-nth=2,3 \
              --prompt='what do you want to do? ' \
              --header=$'\n  type to filter . Enter to run . Esc to cancel\n' \
              --height=50% --layout=reverse --border=rounded --info=hidden \
              --color='hl:cyan,hl+:cyan,header:italic')" || return 0
    [ -n "$choice" ] || return 0
    key="${choice%%	*}"

    case "$key" in
        browse)     y ;;
        workspace)  kdev ;;
        goto)       zi ;;
        goto-work)  zi && kdev ;;
        file)       f ;;
        folder)     cdf ;;
        root)       cdg ;;
        git)        lazygit ;;
        claude)     claude ;;
        keys)       devkeys ;;
    esac
}

# devkeys -- the cheat sheet, also reachable from `dev` -> keys
devkeys() {
    cat <<'CHEAT'

  INSIDE YAZI (the file browser)
    arrows / hjkl   move around
    Enter           open file or enter folder
    q               quit, and your shell lands in that folder
    K               open the full workspace right here
    C               start Claude Code here
    G               git UI here
    !               a shell here

  INSIDE KITTY (the terminal, panes)
    Ctrl+Shift+\            split right
    Ctrl+Shift+'            split down
    Ctrl+Shift+Alt+h j k l  move between panes
    Ctrl+Shift+m            make this pane full screen (and back)
    Ctrl+Shift+r            resize mode: arrows, then Enter
    Ctrl+Shift+p then n     open a file:line printed by Claude
    Ctrl+Shift+<- ->        switch tabs
    Ctrl+Shift+t            new tab

  TYPED COMMANDS
    dev             this menu
    keys            this cheat sheet

CHEAT
}
alias keys='devkeys'
alias '?'='dev'
