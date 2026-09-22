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
| `y` | yazi, and `cd` to wherever you quit (press `q`) |
| `e app/main.py:42` | Open micro at line 42 |

Everything else you use is the tool's own: `z` / `zi` (zoxide), `lazygit`,
`claude`, `micro`, `yazi`, `rg`, `fd`, `bat`.

### Getting to a directory fast

| You want | Do this |
|---|---|
| A repo you've opened before | `z ssi` — zoxide's own jump, one word |
| Pick from everywhere you've been | `zi` — zoxide's interactive list |
| Browse to find it | `y` — yazi opens, navigate, press `q` |
| Somewhere below here | `dev` → "Find a folder and go there" |
| Back to the repo root | `dev` → "Go to the top of this project" |

### Making panes

All kitty's own keys. Nothing to learn that is specific to this repo:

| Key | Does |
|---|---|
| `Ctrl+Shift+Enter` | New pane, **in the directory you are already in** |
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
map kitty_mod+t     new_tab_with_cwd
```

`new_window_with_cwd` and `new_tab_with_cwd` are kitty's own actions, bound to
kitty's own keys — so the keys you press do not change, they just behave like
VS Code's "new terminal opens in the project folder".

### Over SSH

kitty runs on your machine; the remote shell cannot reach it. Splitting still
works, but the new pane is **local** — `ssh` again inside it.

## Supporting tools

| Tool | Replaces | Wired up as |
|---|---|---|
| `lazygit` | VS Code source-control panel | type `lazygit` |
| `delta` | VS Code diff view | git's pager — `git diff`/`log`/`show` |
| `fd` | VS Code file search | fzf's traversal backend |
| `bat` | VS Code syntax highlighting | fzf previews, `$MANPAGER` |
| `ripgrep` | VS Code find-in-files | `rg`, and fzf |

On Debian/Ubuntu the `fd` and `bat` binaries are named `fdfind` and `batcat`;
`install.sh` symlinks them into `~/.local/bin` under the usual names.

## kitty keys

`kitty_mod` is <kbd>Ctrl</kbd>+<kbd>Shift</kbd>. **Every key is kitty's own.**
This config binds no new keys at all — it only points two of kitty's keys at
kitty's own `*_with_cwd` actions, so a new pane or tab opens where you are.

That is deliberate: on a new machine you do not have to work out which keys
came from here. None of them did.

| Key | Does |
|---|---|
| `kitty_mod`+<kbd>Enter</kbd> | New pane, in the current directory |
| `kitty_mod`+<kbd>t</kbd> | New tab, in the current directory |
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
shell/dev-workspace.bash   dev / y / e              -> sourced from ~/.bashrc
install.sh            does all of the above
uninstall.sh          undoes the symlinks and the shell block
```

`install.sh` **symlinks**, so `git pull` in this repo updates your live config.
Anything it would overwrite is moved to
`~/.config/_kitty-dev-setup-backup-<timestamp>/` first.

## Flags

```sh
./install.sh --no-packages   # configs + font only
./install.sh --no-font       # skip the ~130MB Nerd Font download
```

## Requirements

Ubuntu/Debian, Arch, Fedora, or macOS (Homebrew). `install.sh` picks the right
package manager. On Debian it symlinks `fdfind`→`fd` and `batcat`→`bat` into
`~/.local/bin`.

## Troubleshooting

**Every icon is a `▯▯` box.** The Nerd Font is missing or kitty has not
reloaded. Check `fc-list | grep -i "nerd font"`, then *fully quit* kitty —
`Ctrl+Shift+F5` reloads the config but not the font cache.

**Icons render but columns misalign.** You are on the `Mono` font variant.
Use `font_family JetBrainsMono Nerd Font` (no trailing `Mono`) — yazi expects
double-width icons.

**A new pane still opens at `~`.** `local.conf` was not reloaded. Press
`Ctrl+Shift+F5`, or check `grep new_window_with_cwd ~/.config/kitty/local.conf`.

**yazi shows no git signs.** `~/.config/yazi/init.lua` must exist and call
`require("git"):setup{}`. Re-run `./install.sh`.

## License

MIT
