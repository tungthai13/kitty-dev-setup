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

# --remote writes micro's settings as a copy (clipboard: terminal), not a
# symlink. Remove it only while it is still exactly that copy.
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
m="$CFG/micro/settings.json"
if [ -f "$m" ] && [ ! -L "$m" ] && python3 - "$REPO/micro/settings.json" "$m" <<'PY'
import json, sys
with open(sys.argv[1]) as f: want = json.load(f)
want["clipboard"] = "terminal"
with open(sys.argv[2]) as f: have = json.load(f)
sys.exit(0 if have == want else 1)
PY
then rm -v "$m"; fi

# lazydocker: only the copy install.sh downloaded into ~/.local/bin. A brew or
# distro package is left alone, like every other package this repo installs.
[ -f "$HOME/.local/bin/lazydocker" ] && rm -v "$HOME/.local/bin/lazydocker"

# kdev / kpane were removed from this repo; clean up older installs.
for b in kdev kpane; do
  [ -L "$HOME/.local/bin/$b" ] && rm -v "$HOME/.local/bin/$b"
done

# ccstatusline: the config symlink (always under ~/.config -- it ignores
# XDG_CONFIG_HOME), the copy install.sh put in ~/.local, and the statusLine key
# -- only if it still points at ccstatusline, so a user's own line survives.
[ -L "$HOME/.config/ccstatusline/settings.json" ] && rm -v "$HOME/.config/ccstatusline/settings.json"
[ -d "$HOME/.local/lib/node_modules/ccstatusline" ] && command -v npm >/dev/null \
  && npm uninstall -g --prefix "$HOME/.local" ccstatusline >/dev/null && echo "removed ccstatusline"
if [ -f "$HOME/.claude/settings.json" ] && grep -q '"command": *"ccstatusline"' "$HOME/.claude/settings.json"; then
  cp "$HOME/.claude/settings.json" "$HOME/.claude/settings.json.bak.$(date +%Y%m%d-%H%M%S)"
  python3 - "$HOME/.claude/settings.json" <<'PY'
import json, sys
path = sys.argv[1]
with open(path) as f: s = json.load(f)
if s.get("statusLine", {}).get("command") == "ccstatusline":
    del s["statusLine"]
with open(path, "w") as f: json.dump(s, f, indent=2); f.write("\n")
PY
  echo "removed statusLine from ~/.claude/settings.json"
fi

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
