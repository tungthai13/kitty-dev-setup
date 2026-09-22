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

# kdev: open the 3-pane dev workspace (yazi | claude / shell) in $PWD
kdev() {
    local dir="${1:-$PWD}"
    kitty --single-instance \
          --session ~/.config/kitty/dev.session \
          --directory "$dir" >/dev/null 2>&1 &
    disown
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
