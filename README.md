# kitty-dev-setup

A terminal dev workspace that replaces VS Code: **kitty** panes, **yazi** file
tree, **micro** editor, **Claude Code** in the pane next to them.

One command on a fresh machine:

```sh
git clone https://github.com/tungthai13/kitty-dev-setup.git ~/personal/kitty-dev-setup
cd ~/personal/kitty-dev-setup && ./install.sh
```

Then restart kitty, `source ~/.bashrc`, `cd` into a repo and type `dev`.

---

## What you get

Panes you make yourself, with kitty's own keys, whenever you want one:

```
 1: SSI-Backend │ 2: SSI-Frontend │ 3: kitty-dev-setup
┌─────────────┬──────────────────────────────┐
│             │                              │
│    yazi     │        claude code           │
│  file tree  │                              │
│             ├──────────────────────────────┤
│             │        shell                 │
└─────────────┴──────────────────────────────┘
```

Nothing here builds that for you. `Ctrl+Shift+Enter` makes a pane, you run
`yazi` or `claude` in it, `Ctrl+Shift+W` closes it. One pane most of the time,
three when you want three.

| VS Code | Here |
|---|---|
| Explorer sidebar | `yazi` in a pane |
| Editor tabs | micro (`$EDITOR`) |
| Integrated terminal | `Ctrl+Shift+Enter` |
| New terminal opens in the project | `Ctrl+Shift+Enter` — see below |
| Ctrl+click `file:line` | `Ctrl+Shift+P` then `N` |

No tmux. kitty's own `splits` layout does the panes, so there is no extra
render layer between you and the terminal — which is the whole point if you
came here because VS Code's integrated terminal felt slow.

**Tradeoff:** no detach/reattach, and no saved layout. If you need to survive
an SSH drop, add tmux yourself.

---

## Start here

You only need two things:

| Type this | Get this |
|---|---|
| `dev` | A menu of everything. Type to filter, Enter to run. |
| `q` | Inside yazi: quit, and your shell lands in that folder. |

## Commands

This repo adds three, and nothing else:

| Command | Does |
|---|---|
| `dev` | The menu |
| `f` | **f**iles/folders — yazi, and `cd` to wherever you quit (press `q`) |
| `e app/main.py:42` | Open micro at line 42 |

Everything else you use is the tool's own: `z` / `zi` (zoxide), `lazygit`,
`lazydocker`, `claude`, `micro`, `yazi`, `rg`, `fd`, `bat`.

### Getting to a directory fast

| You want | Do this |
|---|---|
| A repo you've opened before | `z ssi` — zoxide's own jump, one word |
| Pick from everywhere you've been | `zi` — zoxide's interactive list |
| Browse to find it | `f` — yazi opens, navigate, press `q` |
| Somewhere below here | `dev` → "Find a folder and go there" |
| Back to the repo root | `dev` → "Go to the top of this project" |

### Making panes

All kitty's own keys. Nothing to learn that is specific to this repo:

| Key | Does |
|---|---|
| `Ctrl+Shift+Enter` | New pane **beside** this one, in the directory you are in |
| `Ctrl+Shift+'` | New pane **below** this one (the one key this repo invents) |
| `Ctrl+Shift+W` | Close this pane |
| `Ctrl+Shift+]` / `[` | Focus the next / previous pane |
| `Ctrl+Shift+F` / `B` | Move this pane forward / back |
| `Ctrl+Shift+L` | Cycle layout — use it to zoom one pane full screen |
| `Ctrl+Shift+R` | Resize — arrows, then Enter |

Then just run what you want in the new pane: `yazi`, `claude`, `lazygit`, or
nothing at all.

### New panes open where you are

Out of the box kitty opens a new pane in the directory kitty was *started* in
— so however deep in a project you are, a new pane lands at `~`. That is the
one kitty behaviour this config changes:

```
map kitty_mod+enter new_window_with_cwd
```

`new_window_with_cwd` is kitty's own action, bound to kitty's own key — so the
key you press does not change, it just behaves like VS Code's "new terminal
opens in the project folder". New tabs (`Ctrl+Shift+T`) are left alone and
start at `~`: a tab is a different piece of work.

### Stacking a pane

kitty's `splits` layout *only* splits side by side — press
`Ctrl+Shift+Enter` three times and you get four columns, never a row. kitty
ships no key for a top/bottom split, so this repo adds the one it is missing:

```
map kitty_mod+apostrophe launch --location=hsplit --cwd=current
```

`Ctrl+Shift+Enter` = a pane beside. `Ctrl+Shift+'` = a pane below. This is the
only invented key in the repo.

### Over SSH

kitty runs on your machine; the server only sees a terminal. To use the rest
of the setup on a server, clone the repo **on the server** and run:

```sh
./install.sh --remote
```

Then always connect with `kitten ssh <host>` instead of `ssh`. kitty sets
`TERM=xterm-kitty`, which most servers do not know — keys, colours and `clear`
break. `kitten ssh` copies that definition to the server for you.

| Works on the server | Does not |
|---|---|
| `dev`, `f`, `e`, yazi, micro, lazygit, lazydocker | New panes — `Ctrl+Shift+Enter` opens a pane on **your** machine; `kitten ssh` again inside it |
| Claude Code and its status line | `Ctrl+Shift+P` then `N` — opens micro on your machine, but the file is on the server |
| Icons — your local kitty draws them with your local font | |

Copy/paste in micro works, but kitty asks each time micro reads your
clipboard (see Troubleshooting).

## Supporting tools

| Tool | Replaces | Wired up as |
|---|---|---|
| `lazygit` | VS Code source-control panel | type `lazygit` |
| `lazydocker` | Docker Desktop's container list | type `lazydocker`, or `dev` → "Manage Docker containers" |
| `delta` | VS Code diff view | git's pager — `git diff`/`log`/`show` |
| `fd` | VS Code file search | fzf's traversal backend |
| `bat` | VS Code syntax highlighting | fzf previews, `$MANPAGER` |
| `ripgrep` | VS Code find-in-files | `rg`, and fzf |
| `ccstatusline` | VS Code status bar | Claude Code's status line — model, context, git, usage |

On Debian/Ubuntu the `fd` and `bat` binaries are named `fdfind` and `batcat`;
`install.sh` symlinks them into `~/.local/bin` under the usual names.

## kitty keys

`kitty_mod` is <kbd>Ctrl</kbd>+<kbd>Shift</kbd>. **One key here is ours**, and
it is the only one in the whole repo: `kitty_mod`+<kbd>'</kbd>. One more line
points kitty's own `kitty_mod`+<kbd>Enter</kbd> at kitty's own
`new_window_with_cwd`. Everything else is
stock kitty.

That is deliberate: on a new machine, the only key you have to remember is
missing is <kbd>'</kbd>.

| Key | Does |
|---|---|
| `kitty_mod`+<kbd>Enter</kbd> | New pane beside this one, in the current directory |
| `kitty_mod`+<kbd>'</kbd> | New pane below this one — **ours**, see below |
| `kitty_mod`+<kbd>t</kbd> | New tab — starts at `~`, a fresh piece of work |
| `kitty_mod`+<kbd>w</kbd> | Close this pane |
| `kitty_mod`+<kbd>]</kbd> / <kbd>[</kbd> | Focus the next / previous pane |
| `kitty_mod`+<kbd>f</kbd> / <kbd>b</kbd> | Move this pane forward / back |
| `kitty_mod`+<kbd>l</kbd> | Cycle layout — zoom a pane full screen and back |
| `kitty_mod`+<kbd>r</kbd> | Resize — arrows, then <kbd>Enter</kbd> |
| `kitty_mod`+<kbd>←→</kbd> | Switch tabs |
| `kitty_mod`+<kbd>p</kbd> then <kbd>n</kbd> | Open a `path:line` from Claude's output — in micro, because of `editor micro` |
| `kitty_mod`+<kbd>p</kbd> then <kbd>f</kbd> / <kbd>l</kbd> / <kbd>w</kbd> | Paste a path / line / word from the screen onto your prompt |

## yazi keys

**One**, and it only adds a case to a yazi default:

| Key | Does | Replaces yazi's |
|---|---|---|
| <kbd>Enter</kbd> | Enter directory / open file (smart-enter) | "Open selected files" |

Everything else you press in yazi is yazi's own.

To start Claude Code, a shell or lazygit in the folder you are browsing, press
<kbd>q</kbd>: yazi quits and your shell lands in that folder. Then type
`claude`, or nothing at all — you are already in a shell.

---

## Layout of this repo

```
kitty/local.conf      kitty settings, 2 key lines   -> ~/.config/kitty/local.conf
yazi/*.toml, init.lua yazi config + plugins         -> ~/.config/yazi/
micro/settings.json   editor settings               -> ~/.config/micro/settings.json
ccstatusline/settings.json  Claude Code status line -> ~/.config/ccstatusline/
shell/dev-workspace.bash   dev / f / e              -> sourced from ~/.bashrc
install.sh            does all of the above
uninstall.sh          undoes the symlinks, the shell block and the statusLine key
```

`install.sh` **symlinks**, so `git pull` in this repo updates your live config.
Anything it would overwrite is moved to
`~/.config/_kitty-dev-setup-backup-<timestamp>/` first.

## Flags

```sh
./install.sh --no-packages   # configs + font only
./install.sh --no-font       # skip the ~130MB Nerd Font download
./install.sh --statusline-only  # only the Claude Code status line (ccstatusline)
./install.sh --remote       # on an SSH server: no kitty, no font, micro set up for SSH
```

`--remote` skips kitty, its config and the Nerd Font (your own machine draws
the screen), and skips wl-clipboard/xclip (a server has no desktop). micro's
settings are written as a **copy** with `"clipboard": "terminal"` instead of a
symlink, so after changing `micro/settings.json`, run `./install.sh --remote`
again on the server. Everything else is the same as a normal install.

`--statusline-only` installs ccstatusline (needs `npm`), links its config and
adds `statusLine` to `~/.claude/settings.json` — nothing else. Your other
Claude Code settings are kept, and an existing `statusLine` is left alone.
Combine with `--no-packages` to skip the npm install.

## Requirements

Ubuntu/Debian, Arch, Fedora, or macOS (Homebrew). `install.sh` picks the right
package manager. On Debian it symlinks `fdfind`→`fd` and `batcat`→`bat` into
`~/.local/bin`.

Older Ubuntu releases do not package everything: 22.04 and 24.04 have no
`lazygit`, and 22.04 has no `git-delta`. `install.sh` installs what apt has
and downloads the rest from their GitHub releases into `~/.local/bin`.

The Claude Code status line needs Node 14 or newer. Ubuntu 22.04's apt Node
is 12, so there `install.sh` skips ccstatusline with a warning — install a
newer Node (for example from NodeSource), then run
`./install.sh --statusline-only`.

## Troubleshooting

**Every icon is a `▯▯` box.** The Nerd Font is missing or kitty has not
reloaded. Check `fc-list | grep -i "nerd font"`, then *fully quit* kitty —
`Ctrl+Shift+F5` reloads the config but not the font cache.

**Icons are `▯` boxes in VS Code's terminal** (including VS Code Remote-SSH).
VS Code draws the terminal on your own machine with its own font setting, not
kitty's. Add this to your *local* VS Code settings (`Ctrl+Shift+P` → "Open
User Settings (JSON)"), then open a new terminal:

```json
"terminal.integrated.fontFamily": "JetBrainsMono Nerd Font",
```

Nothing is needed on the server — fonts are never read there. If the icons
still show as boxes, fully quit and reopen VS Code; it reads fonts at startup.

**Icons render but columns misalign.** You are on the `Mono` font variant.
Use `font_family JetBrainsMono Nerd Font` (no trailing `Mono`) — yazi expects
double-width icons.

**A new pane still opens at `~`.** `local.conf` was not reloaded. Press
`Ctrl+Shift+F5`, or check `grep new_window_with_cwd ~/.config/kitty/local.conf`.

**kitty asks "a program wants to read from the system clipboard" every time
you paste in micro.** micro is set to `"clipboard": "external"`, which talks
to `wl-clipboard` / `xclip` directly and never triggers that prompt. If you
still see it, the setting reverted or neither tool is installed — check
`grep clipboard ~/.config/micro/settings.json` and `command -v wl-copy xclip`.
Over SSH you need `"clipboard": "terminal"` instead (`--remote` sets it), and
the prompt comes back; answering it is the price of a clipboard that crosses
the connection.

**Claude Code has no status line** (the model / context / git / usage lines
under the prompt). It comes from `ccstatusline`. Check `command -v ccstatusline`
(install.sh puts it in `~/.local/bin`) and `grep -A2 statusLine
~/.claude/settings.json`. To change what it shows, run `ccstatusline` -- its
editor saves into `ccstatusline/settings.json` in this repo.

**yazi shows no git signs.** `~/.config/yazi/init.lua` must exist and call
`require("git"):setup{}`. Re-run `./install.sh`.

## License

MIT
