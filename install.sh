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
for arg in "$@"; do
  case "$arg" in
    --no-packages) SKIP_PKGS=1 ;;
    --no-font)     SKIP_FONT=1 ;;
    -h|--help)
      echo "usage: ./install.sh [--no-packages] [--no-font]"; exit 0 ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

say()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[ok]\033[0m %s\n' "$*"; }

# --------------------------------------------------------------------
# 1. Packages
# --------------------------------------------------------------------
CORE_APT=(kitty micro fzf ripgrep fd-find bat zoxide lazygit git-delta git curl unzip)

install_packages() {
  if   command -v apt-get >/dev/null; then
    say "Installing packages with apt"
    sudo apt-get update -qq
    sudo apt-get install -y "${CORE_APT[@]}"
    # Debian names these differently; add shims.
    mkdir -p "$HOME/.local/bin"
    command -v fdfind  >/dev/null && ln -sf "$(command -v fdfind)"  "$HOME/.local/bin/fd"
    command -v batcat  >/dev/null && ln -sf "$(command -v batcat)"  "$HOME/.local/bin/bat"
  elif command -v pacman >/dev/null; then
    say "Installing packages with pacman"
    sudo pacman -S --needed --noconfirm kitty micro fzf ripgrep fd bat zoxide lazygit git-delta git curl unzip
  elif command -v dnf >/dev/null; then
    say "Installing packages with dnf"
    sudo dnf install -y kitty micro fzf ripgrep fd-find bat zoxide lazygit git-delta git curl unzip
  elif command -v brew >/dev/null; then
    say "Installing packages with brew"
    brew install kitty micro fzf ripgrep fd bat zoxide lazygit git-delta
  else
    warn "No supported package manager found. Install manually: ${CORE_APT[*]}"
    return
  fi
  ok "packages"
}

install_yazi() {
  if command -v yazi >/dev/null; then ok "yazi already installed ($(yazi --version | head -1))"; return; fi
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

# --------------------------------------------------------------------
# 2. Nerd Font  (without it every yazi icon renders as a tofu box)
# --------------------------------------------------------------------
install_font() {
  if fc-list 2>/dev/null | grep -qi "$FONT Nerd Font"; then
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
  link "$REPO/kitty/local.conf"    "$CFG/kitty/local.conf"
  link "$REPO/kitty/dev.session"   "$CFG/kitty/dev.session"
  link "$REPO/yazi/init.lua"       "$CFG/yazi/init.lua"
  link "$REPO/yazi/yazi.toml"      "$CFG/yazi/yazi.toml"
  link "$REPO/yazi/keymap.toml"    "$CFG/yazi/keymap.toml"
  link "$REPO/yazi/package.toml"   "$CFG/yazi/package.toml"
  link "$REPO/micro/settings.json" "$CFG/micro/settings.json"
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
# 5. Shell helpers (y / kdev / e)
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
  ok "yazi plugins: $(ls "$CFG/yazi/plugins" 2>/dev/null | tr '\\n' ' ')"
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
  [ "$SKIP_PKGS" -eq 1 ] || { install_packages; install_yazi; install_claude; }
  [ "$SKIP_FONT" -eq 1 ] || install_font
  link_configs
  wire_kitty_conf
  wire_shell
  install_yazi_plugins
  wire_git_delta

  echo
  say "Done. Two things left:"
  echo "  1. Restart kitty completely (font cache is read at startup)."
  echo "  2. Run:  source ~/.bashrc  (or open a new shell)"
  echo
  echo "  Then:  cd <a repo> && kdev"
}
main
