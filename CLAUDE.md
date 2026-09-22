# CLAUDE.md

Guidance for coding agents working in this repository.

## What this is

A dotfiles repo for a terminal dev workspace that replaces VS Code:
**kitty** (panes) + **yazi** (file tree) + **micro** (editor) + **Claude Code**,
with lazygit, delta, fd, bat, fzf and zoxide around them.

`install.sh` **symlinks** the config files into `~/.config/`, so the repo is
the live configuration. Editing a file here changes the user's machine
immediately — there is no build, deploy or copy step. Treat every edit as a
live edit.

## Layout

```
bin/kdev                 workspace launcher: -t new tab, -w new OS window
shell/dev-workspace.bash all shell functions, incl. the kdev that fills the
                         current tab; sourced from ~/.bashrc
kitty/local.conf         kitty options + keybindings (included from kitty.conf)
kitty/dev.session        3-pane layout, only used by `kdev -w`
yazi/{yazi,keymap,package}.toml, yazi/init.lua
micro/settings.json
install.sh / uninstall.sh
```

## Verify before you claim it works

There is no test suite. Run the checks that apply to what you touched:

```sh
bash -n install.sh uninstall.sh bin/kdev shell/dev-workspace.bash

python3 -c "import tomllib,pathlib
for f in ['yazi/yazi.toml','yazi/keymap.toml','yazi/package.toml']:
    tomllib.loads(pathlib.Path(f).read_text()); print('ok',f)"

python3 -c "import json;json.load(open('micro/settings.json'));print('ok micro')"

# kitty parses its own config -- catches typos and bad option names
kitty +runpy 'import os
from kitty.config import load_config
c = load_config(os.path.expanduser("~/.config/kitty/kitty.conf"))
print(c.enabled_layouts, c.editor)'

# session file parses
kitty +runpy 'import os
from kitty.config import load_config
from kitty.session import parse_session
o = load_config(os.path.expanduser("~/.config/kitty/kitty.conf"))
for s in parse_session(open(os.path.expanduser("~/.config/kitty/dev.session")).read(), o):
    for t in s.tabs:
        for w in t.windows:
            print(list(w.launch_spec.args), w.launch_spec.opts.location, w.launch_spec.opts.bias)'
```

### Testing kitty layout changes for real

Do not guess at kitty's split behaviour — drive a scratch instance:

```sh
SOCK=unix:/tmp/kt.sock; rm -f /tmp/kt.sock
setsid kitty --listen-on "$SOCK" -o allow_remote_control=yes \
        -o enabled_layouts=splits,stack --instance-group kt \
        bash -c 'sleep 90' >/tmp/kt.log 2>&1 </dev/null &
until [ -S /tmp/kt.sock ]; do sleep 0.5; done
# ... kitten @ --to $SOCK launch ... then inspect:
kitten @ --to $SOCK ls | python3 -c "import json,sys
for t in json.load(sys.stdin)[0]['tabs']:
    print(t['title'])
    for w in t['windows']:
        print('  ', w.get('title'), w['columns'], w['lines'], w.get('neighbors'))"
kitten @ --to $SOCK close-os-window
```

`ls` output has no `geometry` field in kitty 0.49 — use `columns`, `lines`
and `neighbors` to check placement.

Never use `pkill -f <pattern>` to clean up: the pattern matches the agent's
own shell command line and kills the session. Close instances with
`kitten @ --to $SOCK close-os-window`.

## Gotchas that have already cost time

**yazi templates with `%s`, not `"$@"`.** Changed in yazi 25.5. Openers use
`%s` (all selected) and `%s1` (first); `shell` keymaps use `%h` (hovered),
`%s` (selected). Shell-style `$@` / `$0` silently expands to nothing, so the
editor opens an empty buffer. The authoritative reference is the default
config compiled into the binary:
`strings $(command -v yazi) | grep 'EDITOR'`.

**yazi config section is `[mgr]`, not `[manager]`.** Renamed in 25.5.
Keymaps are `[[mgr.prepend_keymap]]`.

**`ya pkg add` is not idempotent.** On a clean machine `package.toml` is
symlinked in before plugins are installed, so every `add` reports "already
exists". Use `ya pkg install`, which deploys everything `package.toml` lists.

**kitty `--location=vsplit` always adds to the right.** Use
`--location=before` (or `first`) to place a window on the left.

**Every launched kitty window takes focus.** A second `launch` with a bare
`--next-to` will split the window you just created. Always pass an explicit
`--next-to "id:$cur"` and `--dont-take-focus`.

**`--bias` sizes the window being launched**, not the one being split, and it
is ignored for the first window in a tab.

**`listen_on` only applies at kitty startup.** `Ctrl+Shift+F5` will not enable
remote control; the user must fully quit and relaunch kitty. Code that needs
`kitten @` must check `$KITTY_LISTEN_ON` and degrade gracefully.

**`kdev` is both a script and a shell function, deliberately.** The in-place
form ends with `exec claude`, replacing the calling shell with the Claude Code
pane — only a shell function can do that. `bin/kdev` handles `-t` and `-w`, and
the function delegates to it with `command kdev`. Anything callable from yazi
or another program must live in `bin/`, not in `shell/`.

**Do not clobber kitty defaults.** `kitty_mod` + `left/right/up/down/minus/`
`h/j/k/l/z/g/e` are all bound by kitty. An earlier version broke tab switching
and font sizing. Free keys currently used: `\ ' m p` and `kitty_mod+alt+*`.
Check a candidate before binding it:

```sh
grep -E "^# map kitty_mod\+<key> " ~/.config/kitty/kitty.conf
```

and confirm afterwards that the default still resolves, by loading the parsed
config and looking the key up in `keyboard_modes[""].keymap`.

**Never rewrite `~/.config/kitty/kitty.conf`.** It is kitty's 136KB annotated
default. `install.sh` appends two lines (`font_family`, `include local.conf`)
and nothing else, guarded by `grep` so re-runs are safe.

**Debian/Ubuntu name the binaries `fdfind` and `batcat`.** `install.sh`
symlinks them to `fd` and `bat` in `~/.local/bin`.

**Icons rendering as `▯▯` means no Nerd Font**, or kitty has not been fully
restarted — a config reload does not reload the font cache. Use the non-`Mono`
font variant; yazi expects double-width icons.

## Conventions

- `install.sh` must stay **re-runnable**. Back up anything it would overwrite
  into `~/.config/_kitty-dev-setup-backup-<timestamp>/`, and guard every append
  with a `grep` for a marker.
- Shell block in `~/.bashrc` is delimited by `# >>> kitty-dev-setup >>>` and
  `# <<< kitty-dev-setup <<<`; `uninstall.sh` deletes between those markers.
  Do not change the markers without changing both scripts.
- Anything added to `install.sh` needs a matching removal in `uninstall.sh`.
- Keep the package lists in sync across the apt/pacman/dnf/brew branches.
- The user is new to the terminal. Command names and `dev` menu labels are
  plain English on purpose; `dev` and `keys` are the discoverable entry points
  and should stay complete when new commands are added.
- Document any new command in `README.md` and add it to the `dev` menu in
  `shell/dev-workspace.bash`.

## Commit style

Explain the failure, not just the change — these commits are the only record
of the kitty and yazi behaviour above. State what was verified and how.
