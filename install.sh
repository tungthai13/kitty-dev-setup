#!/usr/bin/env bash
# install.sh -- set up the kitty + yazi + micro + Claude Code workspace.
# Safe to re-run: existing files are backed up, symlinks are refreshed.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP="$CFG/_kitty-dev-setup-backup-$(date +%Y%m%d-%H%M%S)"
FONT="JetBrainsMono"
MARK_BEGIN="# >>> kitty-dev-setup >>>"
MARK_END="# <<< kitty-dev-setup <<<"

SKIP_PKGS=0
SKIP_FONT=0
ONLY_STATUSLINE=0
REMOTE=0
for arg in "$@"; do
  case "$arg" in
    --no-packages) SKIP_PKGS=1 ;;
    --no-font)     SKIP_FONT=1 ;;
    --statusline-only) ONLY_STATUSLINE=1 ;;
    --remote)      REMOTE=1; SKIP_FONT=1 ;;
    -h|--help)
      echo "usage: ./install.sh [--no-packages] [--no-font] [--statusline-only] [--remote]"; exit 0 ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

# Fallback installs land in ~/.local/bin. On a fresh Ubuntu login it is not on
# PATH until the next login, so later steps (wire_git_delta) would not see them.
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac

say()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[ok]\033[0m %s\n' "$*"; }

# --------------------------------------------------------------------
# 1. Packages
# --------------------------------------------------------------------
CORE_APT=(kitty micro fzf ripgrep fd-find bat zoxide lazygit git-delta git curl unzip
          wl-clipboard xclip nodejs npm)

# --remote: a server you reach with `kitten ssh`. kitty runs on your own machine,
# and wl-clipboard/xclip need a desktop session the server does not have.
pkgs() {
  local p
  for p in "$@"; do
    if [ "$REMOTE" -eq 1 ]; then case "$p" in kitty|wl-clipboard|xclip) continue ;; esac; fi
    printf '%s\n' "$p"
  done
}

install_packages() {
  if   command -v apt-get >/dev/null; then
    say "Installing packages with apt"
    sudo apt-get update -qq
    # Older releases lack some of these (lazygit before 25.04, git-delta on
    # 22.04), and apt refuses the whole list if one name is unknown. Install
    # what apt has; the GitHub-release fallbacks below cover the rest.
    # (Output captured, not piped into grep -q: under pipefail, grep exiting
    # early SIGPIPEs apt-cache and every package reads as missing.)
    local want=() missing=() p pol
    for p in $(pkgs "${CORE_APT[@]}"); do
      # A node that is already here (NodeSource, nvm, ...) is the user's.
      # NodeSource's nodejs bundles npm and Conflicts: npm, so asking apt for
      # Ubuntu's npm on top of it fails the whole install.
      case "$p" in nodejs|npm) command -v node >/dev/null && continue ;; esac
      pol="$(apt-cache policy "$p" 2>/dev/null)"
      if [[ "$pol" == *"Candidate: "[!\(]* ]]; then want+=("$p"); else missing+=("$p"); fi
    done
    [ "${#missing[@]}" -eq 0 ] || warn "apt has no ${missing[*]} -- installing from GitHub instead"
    sudo apt-get install -y "${want[@]}"
    # Debian names these differently; add shims.
    mkdir -p "$HOME/.local/bin"
    command -v fdfind  >/dev/null && ln -sf "$(command -v fdfind)"  "$HOME/.local/bin/fd"
    command -v batcat  >/dev/null && ln -sf "$(command -v batcat)"  "$HOME/.local/bin/bat"
  elif command -v pacman >/dev/null; then
    say "Installing packages with pacman"
    sudo pacman -S --needed --noconfirm $(pkgs kitty micro fzf ripgrep fd bat zoxide lazygit git-delta git curl unzip wl-clipboard xclip nodejs npm)
  elif command -v dnf >/dev/null; then
    say "Installing packages with dnf"
    sudo dnf install -y $(pkgs kitty micro fzf ripgrep fd-find bat zoxide lazygit git-delta git curl unzip wl-clipboard xclip nodejs npm)
  elif command -v brew >/dev/null; then
    say "Installing packages with brew"
    brew install $(pkgs kitty micro fzf ripgrep fd bat zoxide lazygit git-delta node)
  else
    warn "No supported package manager found. Install manually: $(pkgs "${CORE_APT[@]}" | tr '\n' ' ')lazydocker"
    return
  fi
  ok "packages"
}

# yazi 26 prints a multi-line --version ("Yazi" / "  Version: 26.9.1 ...");
# older builds print "Yazi 25.5.31 (...)" on one line. awk reads to EOF --
# `| head -1` closes the pipe early and yazi panics with "Broken pipe".
yazi_version() {
  yazi --version 2>/dev/null | awk 'NR==1 {v=$2} /Version:/ {v=$2} END {print v}'
}

install_yazi() {
  if command -v yazi >/dev/null; then ok "yazi already installed ($(yazi_version))"; return; fi
  say "Installing yazi"
  if   command -v pacman >/dev/null; then sudo pacman -S --needed --noconfirm yazi
  elif command -v brew   >/dev/null; then brew install yazi
  elif command -v snap   >/dev/null; then sudo snap install yazi --classic
  elif command -v cargo  >/dev/null; then cargo install --locked yazi-fm yazi-cli
  else
    warn "Install yazi manually: https://yazi-rs.github.io/docs/installation"
    return
  fi
  ok "yazi"
}

install_claude() {
  if command -v claude >/dev/null; then ok "Claude Code already installed ($(claude --version))"; return; fi
  say "Installing Claude Code"
  curl -fsSL https://claude.ai/install.sh | bash || warn "Claude Code install failed -- see https://docs.claude.com/en/docs/claude-code"
}

# lazygit, lazydocker and delta are not in every distro's repos (apt/dnf have
# no lazydocker; Ubuntu before 25.04 has no lazygit; 22.04 has no delta), so
# each falls back to its GitHub release tarball, installed into ~/.local/bin.
# The version is *in* the asset filename, so /releases/latest/download/ cannot
# be used -- the tag is resolved from the /releases/latest redirect first.
gh_latest_tag() {
  local url
  url="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest")" || return 1
  printf '%s\n' "${url##*/}"
}

# gh_install <binary> <tarball url>: unpack in a tmpdir (upstream install
# scripts unpack into $PWD and leave debris on failure) and install the binary.
gh_install() {
  local bin="$1" url="$2" tmp f
  tmp="$(mktemp -d)"
  if curl -fL --retry 3 -so "$tmp/a.tar.gz" "$url" && tar -xzf "$tmp/a.tar.gz" -C "$tmp" \
     && f="$(find "$tmp" -type f -name "$bin" -print -quit)" && [ -n "$f" ]; then
    install -Dm755 "$f" "$HOME/.local/bin/$bin"
    rm -rf "$tmp"; return 0
  fi
  rm -rf "$tmp"; return 1
}

# lazygit and lazydocker share a release naming scheme, except lazygit writes
# "linux" and lazydocker "Linux".
install_jesseduffield() {
  local name="$1" os="$2" arch tag
  if command -v "$name" >/dev/null; then ok "$name already installed"; return; fi
  if command -v brew >/dev/null; then brew install "$name" && ok "$name"; return; fi
  case "$(uname -m)" in
    x86_64)        arch=x86_64 ;;
    aarch64|arm64) arch=arm64 ;;
    armv6*|armv7*) arch=armv6 ;;
    *) warn "no $name build for $(uname -m) -- skipping"; return ;;
  esac
  say "Installing $name from GitHub"
  tag="$(gh_latest_tag "jesseduffield/$name")" || { warn "could not reach GitHub -- skipping $name"; return; }
  if gh_install "$name" "https://github.com/jesseduffield/$name/releases/download/$tag/${name}_${tag#v}_${os}_$arch.tar.gz"; then
    ok "$name $tag -> ~/.local/bin"
  else
    warn "$name download failed -- see https://github.com/jesseduffield/$name"
  fi
}
install_lazygit()    { install_jesseduffield lazygit linux; }
install_lazydocker() { install_jesseduffield lazydocker Linux; }

install_delta() {
  local arch tag
  if command -v delta >/dev/null; then ok "delta already installed"; return; fi
  case "$(uname -m)" in
    x86_64)        arch=x86_64-unknown-linux-musl ;;   # static: no glibc floor
    aarch64|arm64) arch=aarch64-unknown-linux-gnu ;;
    *) warn "no delta build for $(uname -m) -- skipping"; return ;;
  esac
  say "Installing delta from GitHub"
  tag="$(gh_latest_tag dandavison/delta)" || { warn "could not reach GitHub -- skipping delta"; return; }
  if gh_install delta "https://github.com/dandavison/delta/releases/download/$tag/delta-$tag-$arch.tar.gz"; then
    ok "delta $tag -> ~/.local/bin"
  else
    warn "delta download failed -- see https://github.com/dandavison/delta"
  fi
}

# ccstatusline draws Claude Code's status line (model, context, git, usage).
# Pinned to match the "installation" block in ccstatusline/settings.json.
# --prefix ~/.local: no sudo, and the binary lands in ~/.local/bin next to the
# fd/bat shims. A distro npm's default global prefix is /usr and needs root.
CCSTATUSLINE_VERSION=2.2.30
install_ccstatusline() {
  local have=""
  command -v ccstatusline >/dev/null && have="$(ccstatusline --version 2>/dev/null || true)"
  if [ "$have" = "$CCSTATUSLINE_VERSION" ]; then ok "ccstatusline $have already installed"; return; fi
  # A copy this script did not put in ~/.local (brew, a system npm) is the
  # user's; leave it. Our own copy is moved to the pinned version.
  if [ -n "$have" ] && [ ! -d "$HOME/.local/lib/node_modules/ccstatusline" ]; then
    ok "ccstatusline $have already installed (not ours -- left as is)"; return
  fi
  command -v npm >/dev/null || { warn "npm not found -- install node, then re-run ./install.sh --statusline-only"; return; }
  # ccstatusline needs node >= 14; Ubuntu 22.04's apt node is 12.
  local node_major
  node_major="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
  if [ "$node_major" -lt 14 ]; then
    warn "ccstatusline needs node 14+, this is $(node --version 2>/dev/null || echo none) -- install a newer node (e.g. nodesource), then re-run ./install.sh --statusline-only"
    return
  fi
  say "Installing ccstatusline $CCSTATUSLINE_VERSION"
  npm install -g --prefix "$HOME/.local" "ccstatusline@$CCSTATUSLINE_VERSION" >/dev/null \
    && ok "ccstatusline -> ~/.local/bin" \
    || warn "ccstatusline install failed -- see https://github.com/sirmalloc/ccstatusline"
}

# --------------------------------------------------------------------
# 2. Nerd Font  (without it every yazi icon renders as a tofu box)
# --------------------------------------------------------------------
install_font() {
  # No pipe: under pipefail `fc-list | grep -q` reads as false once grep exits
  # on the match and fc-list takes SIGPIPE (grep >/dev/null does the same).
  local fonts; fonts="$(fc-list 2>/dev/null || true)"
  if grep -qi "$FONT Nerd Font" <<<"$fonts"; then
    ok "$FONT Nerd Font already installed"; return
  fi
  say "Installing $FONT Nerd Font"
  local dir="$HOME/.local/share/fonts/${FONT}NF" tmp
  tmp="$(mktemp -d)"
  mkdir -p "$dir"
  curl -fL --retry 3 -o "$tmp/$FONT.zip" \
    "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$FONT.zip"
  unzip -oq "$tmp/$FONT.zip" -d "$dir"
  rm -rf "$tmp"
  fc-cache -f >/dev/null
  ok "$FONT Nerd Font ($(fc-list | grep -ci "$FONT Nerd Font") faces)"
}

# --------------------------------------------------------------------
# 3. Config symlinks
# --------------------------------------------------------------------
link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    rm -f "$dst"
  elif [ -e "$dst" ]; then
    mkdir -p "$BACKUP/$(dirname "${dst#$CFG/}")"
    mv "$dst" "$BACKUP/${dst#$CFG/}"
    warn "backed up ${dst/#$HOME/\~} -> ${BACKUP/#$HOME/\~}"
  fi
  ln -s "$src" "$dst"
  ok "${dst/#$HOME/\~}"
}

link_configs() {
  say "Linking configs"
  [ "$REMOTE" -eq 1 ] || link "$REPO/kitty/local.conf" "$CFG/kitty/local.conf"
  link "$REPO/yazi/init.lua"       "$CFG/yazi/init.lua"
  link "$REPO/yazi/yazi.toml"      "$CFG/yazi/yazi.toml"
  link "$REPO/yazi/keymap.toml"    "$CFG/yazi/keymap.toml"
  link "$REPO/yazi/package.toml"   "$CFG/yazi/package.toml"
  if [ "$REMOTE" -eq 1 ]; then copy_micro_remote; else
    link "$REPO/micro/settings.json" "$CFG/micro/settings.json"
  fi
  link_ccstatusline
}

# On a server micro cannot reach wl-clipboard/xclip, so it needs "terminal"
# (OSC 52 -- kitty on your machine asks before each paste). That differs from
# the repo file, so this is a copy, not a symlink: re-run --remote after
# changing micro/settings.json. uninstall.sh recognises the copy by content.
micro_remote_json() {
  python3 - "$REPO/micro/settings.json" <<'PY'
import json, sys
with open(sys.argv[1]) as f: s = json.load(f)
s["clipboard"] = "terminal"
print(json.dumps(s, indent=4))
PY
}

copy_micro_remote() {
  local dst="$CFG/micro/settings.json" want
  want="$(micro_remote_json)"
  if [ -f "$dst" ] && [ ! -L "$dst" ] && [ "$(cat "$dst")" = "$want" ]; then
    ok "${dst/#$HOME/\~} (copy, clipboard: terminal) already up to date"; return
  fi
  link "$REPO/micro/settings.json" "$dst" >/dev/null   # backs up the user's own file
  rm -f "$dst"
  printf '%s\n' "$want" > "$dst"
  ok "${dst/#$HOME/\~} (copy, clipboard: terminal)"
}

link_ccstatusline() {
  # ccstatusline hardcodes ~/.config -- it ignores XDG_CONFIG_HOME. Its TUI
  # saves through the symlink (it realpath()s before the atomic rename), so
  # edits made in `ccstatusline` land in this repo.
  CFG="$HOME/.config" link "$REPO/ccstatusline/settings.json" "$HOME/.config/ccstatusline/settings.json"
}

# --------------------------------------------------------------------
# 3b. Claude Code status line -- merge one key into ~/.claude/settings.json.
# That file holds the user's permissions, plugins and model; never replace it.
# An existing statusLine that is not ccstatusline is left alone.
# --------------------------------------------------------------------
wire_claude_statusline() {
  local conf="$HOME/.claude/settings.json"
  mkdir -p "$HOME/.claude"
  [ -s "$conf" ] || printf '{}\n' > "$conf"
  if grep -q '"statusLine"' "$conf"; then
    ok "Claude Code already has a statusLine -- left as is"; return
  fi
  mkdir -p "$BACKUP/claude"
  cp "$conf" "$BACKUP/claude/settings.json"
  python3 - "$conf" <<'PY'
import json, sys
path = sys.argv[1]
with open(path) as f: s = json.load(f)
s["statusLine"] = {"type": "command", "command": "ccstatusline",
                   "padding": 0, "refreshInterval": 10}
with open(path, "w") as f: json.dump(s, f, indent=2); f.write("\n")
PY
  ok "Claude Code statusLine -> ccstatusline"
}

# --------------------------------------------------------------------
# 4. kitty.conf -- append include + font, never rewrite the user's file
# --------------------------------------------------------------------
wire_kitty_conf() {
  local conf="$CFG/kitty/kitty.conf"
  mkdir -p "$CFG/kitty"
  [ -f "$conf" ] || printf '# kitty.conf\n' > "$conf"

  if ! grep -q '^font_family .*Nerd Font' "$conf"; then
    printf '\nfont_family %s Nerd Font\nfont_size 11.0\n' "$FONT" >> "$conf"
    ok "font_family appended to kitty.conf"
  else
    ok "kitty.conf already selects a Nerd Font"
  fi

  if ! grep -q '^include local.conf' "$conf"; then
    printf '\n# --- kitty-dev-setup ---\ninclude local.conf\n' >> "$conf"
    ok "include local.conf appended to kitty.conf"
  else
    ok "kitty.conf already includes local.conf"
  fi
}

# --------------------------------------------------------------------
# 5. Shell helpers (y / e / dev)
# --------------------------------------------------------------------
wire_shell() {
  local rc
  case "${SHELL##*/}" in
    zsh)  rc="$HOME/.zshrc" ;;
    *)    rc="$HOME/.bashrc" ;;
  esac
  [ -f "$rc" ] || touch "$rc"

  if grep -qF "$MARK_BEGIN" "$rc"; then
    ok "${rc/#$HOME/\~} already wired"
    return
  fi
  # Drop the older unmanaged block from a hand-rolled setup, if present.
  {
    printf '\n%s\n' "$MARK_BEGIN"
    printf 'source "%s/shell/dev-workspace.bash"\n' "$REPO"
    printf 'command -v zoxide >/dev/null && eval "$(zoxide init %s)"\n' "${SHELL##*/}"
    printf 'export EDITOR=micro\nexport VISUAL=micro\n'
    printf '%s\n' "$MARK_END"
  } >> "$rc"
  ok "${rc/#$HOME/\~}"
}

# --------------------------------------------------------------------
# 6. yazi plugins
# --------------------------------------------------------------------
install_yazi_plugins() {
  command -v ya >/dev/null || { warn "'ya' not found -- skipping yazi plugins"; return; }
  say "Installing yazi plugins from package.toml"
  # `ya pkg install` deploys every dep listed in the symlinked package.toml.
  ya pkg install || warn "ya pkg install failed -- run it by hand"
  ok "yazi plugins: $(ls "$CFG/yazi/plugins" 2>/dev/null | tr '\n' ' ')"
}

# --------------------------------------------------------------------
# 7. git -> delta  (the diff half of VS Code's source-control panel)
# --------------------------------------------------------------------
wire_git_delta() {
  command -v delta >/dev/null || { warn "delta not installed -- skipping git pager config"; return; }
  say "Pointing git at delta"
  git config --global core.pager             "delta"
  git config --global interactive.diffFilter "delta --color-only"
  git config --global delta.navigate         true
  git config --global delta.line-numbers     true
  git config --global delta.hyperlinks       true
  git config --global merge.conflictstyle    zdiff3
  git config --global diff.colorMoved        default
  ok "git diff / log / show now render through delta"
}

# --------------------------------------------------------------------
main() {
  say "kitty-dev-setup -- $REPO"
  if [ "$ONLY_STATUSLINE" -eq 1 ]; then
    # Just the Claude Code status line: no packages, font, kitty, yazi or shell.
    [ "$SKIP_PKGS" -eq 1 ] || install_ccstatusline
    link_ccstatusline
    wire_claude_statusline
    echo; say "Done. Start a new Claude Code session to see the status line."
    return
  fi
  [ "$SKIP_PKGS" -eq 1 ] || { install_packages; install_yazi; install_claude; install_lazygit; install_delta; install_lazydocker; install_ccstatusline; }
  [ "$SKIP_FONT" -eq 1 ] || install_font
  link_configs
  wire_claude_statusline
  [ "$REMOTE" -eq 1 ] || wire_kitty_conf
  wire_shell
  install_yazi_plugins
  wire_git_delta

  echo
  if [ "$REMOTE" -eq 1 ]; then
    say "Done. Run:  source ~/.bashrc  (or log in again)"
    echo "  Connect from your own machine with:  kitten ssh <host>"
    echo "  (plain ssh leaves the server without kitty's terminfo)"
    echo
    echo "  Then:  cd <a repo> && dev"
    return
  fi
  say "Done. Two things left:"
  echo "  1. Restart kitty completely (font cache is read at startup)."
  echo "  2. Run:  source ~/.bashrc  (or open a new shell)"
  echo
  echo "  Then:  cd <a repo> && dev"
}
main
