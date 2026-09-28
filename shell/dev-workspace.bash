# f -- files/folders. Opens yazi, and when you quit with `q` your shell
# lands in the directory you were browsing (Q quits without moving).
f() {
    local tmp cwd
    tmp="$(mktemp -t yazi-cwd.XXXXXX)"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd" || return
    fi
    rm -f -- "$tmp"
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

# ---------------------------------------------------------------------
# dev -- the only command you have to remember.
# Opens a searchable menu of everything else. Type to filter, Enter to run.
# ---------------------------------------------------------------------
dev() {
    local choice key
    # format: key <TAB> label <TAB> hint
    choice="$(printf '%s\n' \
"browse	Browse files here	yazi - arrows to move, q to come back" \
"goto	Go to another project	pick from folders you have visited" \
"file	Find a file and edit it	fuzzy search, opens in micro" \
"folder	Find a folder and go there	fuzzy search below here" \
"root	Go to the top of this project	git repo root" \
"claude	Start Claude Code here	" \
"docker	Manage Docker containers	lazydocker - logs, restart, remove" \
        | fzf --delimiter='\t' --with-nth=2,3 \
              --prompt='what do you want to do? ' \
              --header=$'\n  type to filter . Enter to run . Esc to cancel\n' \
              --height=50% --layout=reverse --border=rounded --info=hidden \
              --color='hl:cyan,hl+:cyan,header:italic')" || return 0
    [ -n "$choice" ] || return 0
    key="${choice%%	*}"

    case "$key" in
        browse) f ;;
        goto)   zi ;;
        file)   local f
                f="$(fzf --preview 'bat --color=always --style=numbers --line-range=:200 {}')" \
                    && [ -n "$f" ] && "${EDITOR:-micro}" "$f" ;;
        folder) local d
                d="$(fd --type d --hidden --follow --exclude .git 2>/dev/null \
                     | fzf --preview 'ls -la --color=always {}')" \
                    && [ -n "$d" ] && builtin cd -- "$d" ;;
        root)   local r
                r="$(git rev-parse --show-toplevel 2>/dev/null)" \
                    && builtin cd -- "$r" || echo "not in a git repo" >&2 ;;
        claude) claude ;;
        docker) lazydocker ;;
    esac
}
