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
