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

# ---------------------------------------------------------------------
# kdev -- build the 3-pane workspace IN THE TAB YOU ARE IN.
#
#   kdev            here, in this tab   (yazi left, Claude here, shell below)
#   kdev <dir>      same, for that directory
#   kdev -t [dir]   new tab instead
#   kdev -w [dir]   new OS window instead
#
# This has to be a shell function, not a script: the last step replaces
# THIS shell with Claude Code, and only the shell itself can do that.
# ---------------------------------------------------------------------
kdev() {
    local dir="" arg
    for arg in "$@"; do
        case "$arg" in
            -t|--tab|-w|--window) command kdev "$@"; return $? ;;
            -h|--help)            command kdev --help; return 0 ;;
            *)                    dir="$arg" ;;
        esac
    done

    dir="${dir:-$PWD}"
    [ -d "$dir" ] || dir="$(dirname "$dir")"
    dir="$(cd "$dir" && pwd)" || return 1
    local name; name="$(basename "$dir")"

    if [ -z "${KITTY_LISTEN_ON:-}" ]; then
        echo "kdev: kitty remote control is off -- opening a new window instead." >&2
        echo "      Fully quit and relaunch kitty (listen_on needs a restart)." >&2
        command kdev -w "$dir"
        return
    fi

    # Already split? Don't wreck the layout -- use a fresh tab.
    local n
    n=$(kitten @ ls 2>/dev/null | python3 -c "
import json,sys
try:
    for osw in json.load(sys.stdin):
        for t in osw['tabs']:
            if any(w.get('is_self') for w in t['windows']):
                print(len(t['windows'])); raise SystemExit
except Exception: pass
print(1)" | head -1)
    if [ "${n:-1}" -gt 1 ]; then
        echo "kdev: this tab already has $n panes -- opening a new tab instead." >&2
        command kdev -t "$dir"
        return
    fi

    # Both launches must target THIS window explicitly: each new window
    # takes focus, so a bare --next-to would split the pane just created.
    local cur="${KITTY_WINDOW_ID:?}"
    kitten @ set-tab-title "$name" >/dev/null 2>&1 || true
    kitten @ launch --type=window --location=before --bias 30 \
            --cwd "$dir" --window-title files \
            --next-to "id:$cur" --dont-take-focus yazi >/dev/null || return 1
    kitten @ launch --type=window --location=hsplit --bias 30 \
            --cwd "$dir" --window-title shell \
            --next-to "id:$cur" --dont-take-focus >/dev/null || return 1
    kitten @ set-window-title --match "id:$cur" claude >/dev/null 2>&1 || true
    kitten @ focus-window --match "id:$cur" >/dev/null 2>&1 || true

    builtin cd -- "$dir" || return 1
    exec claude          # this shell becomes the Claude Code pane
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
"pane-files	Add a file browser pane	yazi on the left" \
"pane-shell	Add a shell pane	a terminal below" \
"pane-claude	Add a Claude Code pane	on the right" \
"goto	Go to another project	pick from folders you have visited" \
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
        pane-files)  kpane files ;;
        pane-shell)  kpane shell ;;
        pane-claude) kpane claude ;;
        goto)       zi ;;
        file)       f ;;
        folder)     local d
                    d="$(fd --type d --hidden --follow --exclude .git 2>/dev/null \
                         | fzf --preview 'ls -la --color=always {}')" \
                        && [ -n "$d" ] && builtin cd -- "$d" ;;
        root)       local r
                    r="$(git rev-parse --show-toplevel 2>/dev/null)" \
                        && builtin cd -- "$r" || echo "not in a git repo" >&2 ;;
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
    Alt+c           Claude Code, seeded with the file you are on
    G               git UI here
    !               a shell here

  INSIDE KITTY (the terminal, panes)
    Ctrl+Shift+\            split right (empty shell)
    Ctrl+Shift+'            split down (empty shell)
    Ctrl+Shift+w            close this pane
    Ctrl+Shift+] [          focus the next / previous pane
    Ctrl+Shift+f b          move this pane forward / back
    Ctrl+Shift+m            make this pane full screen (and back)
    Ctrl+Shift+r            resize mode: arrows, then Enter
    Ctrl+Shift+p then n     open a file:line printed by Claude, in micro
    Ctrl+Shift+p then f     paste a path from the screen onto your prompt
    Ctrl+Shift+<- ->        switch tabs
    Ctrl+Shift+t            new tab

  TYPED COMMANDS -- this is all of them
    dev             this menu (also: ?)
    keys            this cheat sheet

    y               browse with yazi, land where you quit
    z ssi           jump to a project you have opened before (zoxide)
    zi              ...or pick one from a list

    f               find a file and open it in micro
    e main.py:42    open that file at that line
    lg              git UI (lazygit)

    kpane files     add ONE pane: files | shell | claude
    kdev            all three panes at once

CHEAT
}
alias keys='devkeys'
alias '?'='dev'
