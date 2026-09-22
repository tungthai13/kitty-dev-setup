#!/usr/bin/env bash
# uninstall.sh -- remove the symlinks and shell block this repo installed.
# Packages and the Nerd Font are left alone.
set -euo pipefail
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
MARK_BEGIN="# >>> kitty-dev-setup >>>"
MARK_END="# <<< kitty-dev-setup <<<"

for f in kitty/local.conf kitty/dev.session \
         yazi/init.lua yazi/yazi.toml yazi/keymap.toml yazi/package.toml \
         micro/settings.json; do
  [ -L "$CFG/$f" ] && rm -v "$CFG/$f"
done

# kdev / kpane were removed from this repo; clean up older installs.
for b in kdev kpane; do
  [ -L "$HOME/.local/bin/$b" ] && rm -v "$HOME/.local/bin/$b"
done

for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  [ -f "$rc" ] || continue
  if grep -qF "$MARK_BEGIN" "$rc"; then
    cp "$rc" "$rc.bak.$(date +%Y%m%d-%H%M%S)"
    sed -i "/$MARK_BEGIN/,/$MARK_END/d" "$rc"
    echo "cleaned $rc"
  fi
done

sed -i '/^include local.conf$/d; /^# --- kitty-dev-setup ---$/d' "$CFG/kitty/kitty.conf" 2>/dev/null || true
echo "Done. Restart kitty."
