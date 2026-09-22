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
