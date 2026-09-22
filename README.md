# kitty-dev-setup

A terminal dev workspace that replaces VS Code: **kitty** panes, **yazi** file
tree, **micro** editor, **Claude Code** in the pane next to them.

One command on a fresh machine:

```sh
git clone https://github.com/tungthai13/kitty-dev-setup.git ~/personal/kitty-dev-setup
cd ~/personal/kitty-dev-setup && ./install.sh
```

Then restart kitty, `source ~/.bashrc`, `cd` into a repo and run `kdev`.

---

## What you get

One tab per project. Open a kitty tab, `cd` to the project, run `kdev`: that
tab becomes the workspace and is renamed after the project folder. Your shell
turns into the Claude Code pane, so nothing is left over:

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

| VS Code | Here |
|---|---|
| Explorer sidebar | yazi pane |
| Editor tabs | micro (`$EDITOR`) |
| Integrated terminal | kitty split |
| Ctrl+click `file:line` | `Ctrl+Shift+P` then `N` |
| Workspace layout | `kdev` |
| Source control panel | `G` in yazi (lazygit) |

No tmux. kitty's own `splits` layout does the panes, so there is no extra
render layer between you and the terminal — which is the whole point if you
came here because VS Code's integrated terminal felt slow.

**Tradeoff:** no detach/reattach. `kdev` restores the *layout*, not running
processes. If you need to survive an SSH drop, add tmux yourself.

---

## Start here

You only need three things:

| Type this | Get this |
|---|---|
| `dev` | A menu of everything. Type to filter, Enter to run. |
| `keys` | The keyboard cheat sheet. |
| `q` | Inside yazi: quit, and your shell lands in that folder. |

Everything below is what `dev` runs for you. Learn it if you want to skip the
menu; ignore it otherwise.

## Commands

| Command | Does |
|---|---|
| `kdev` | Turn **this tab** into the 3-pane workspace |
| `kdev ~/some/repo` | Same, for that directory |
| `kdev -t` | New tab instead |
| `kdev -w` | New OS window instead |
| `kpane files` | Add **one** pane: yazi on the left |
| `kpane shell` | Add **one** pane: a shell below |
| `kpane claude` | Add **one** pane: Claude Code on the right |
| `y` | yazi, and `cd` to wherever you quit (press `q`) |
| `e app/main.py:42` | Open micro at line 42 |
| `f` | Fuzzy-find a file (fzf + bat preview) and open it |
| `lg` | lazygit |

### One pane at a time

`kdev` gives you all three panes. Most of the time you want fewer — just a
shell for `docker compose`, just yazi to look around, just Claude Code. Start
with one pane and add the others when you need them:

| You want | Do |
|---|---|
| Just read a file | `e path/to/file` (or `y`, then <kbd>Enter</kbd>) |
| Just a terminal | a plain tab — `kitty_mod`+<kbd>t</kbd> |
| Just browse files | `y` |
| Just Claude Code | `claude` |
| ...and now a shell too | `kpane shell` |
| ...and now the file tree | `kpane files` |
| Done with a pane | `kitty_mod`+<kbd>w</kbd>, or type `exit` |

Each pane lands in the slot `kdev` would have used, so however you build it up
you end up with the same layout. `kpane` needs kitty's remote control; without
it, it runs the program in the current pane instead of failing.

### Over SSH

kitty runs on your machine, the remote shell cannot reach it. Splitting with
`kitty_mod`+<kbd>\\</kbd> still works, but the new pane is **local** — `ssh`
again inside it. `kdev` and `kpane` typed on the remote host have no socket to
talk to: `kpane` runs the program in the current pane instead, and `kdev` falls
back to a new window.

### Getting to a directory fast

These only `cd`. They do not open panes — add those yourself afterwards with
`kpane`, or all three at once with `kdev`.

| You want | Do this |
|---|---|
| A repo you've opened before | `zd ssi` — zoxide jump, one word |
| Pick from everywhere you've been | `zd` — interactive zoxide list |
| Browse to find it | `y` — yazi opens, navigate, press `q` |
| Somewhere below here | `cdf` — fuzzy directory picker |
| Back to the repo root | `cdg` |

`K` inside yazi still opens the full workspace in the folder you are on, since
that one is a deliberate "I want all three panes here".

`kdev` and `kpane` are scripts on `$PATH` (`bin/`), so they work from yazi,
scripts and any shell — not just an interactive bash session.

## Supporting tools

| Tool | Replaces | Wired up as |
|---|---|---|
| `lazygit` | VS Code source-control panel | `lg`, or `G` inside yazi |
| `delta` | VS Code diff view | git's pager — `git diff`/`log`/`show` |
| `fd` | VS Code file search | fzf's traversal backend |
| `bat` | VS Code syntax highlighting | fzf previews, `$MANPAGER` |
| `ripgrep` | VS Code find-in-files | `rg`, and fzf |

On Debian/Ubuntu the `fd` and `bat` binaries are named `fdfind` and `batcat`;
`install.sh` symlinks them into `~/.local/bin` under the usual names.

## kitty keys

`kitty_mod` is <kbd>Ctrl</kbd>+<kbd>Shift</kbd>. **Every kitty default still
works** — this config only binds keys kitty leaves free.

| Key | Does |
|---|---|
| `kitty_mod`+<kbd>\\</kbd> | Split right (plain shell) |
| `kitty_mod`+<kbd>'</kbd> | Split down (plain shell) |
| `kitty_mod`+<kbd>m</kbd> | Zoom the focused pane (toggle stack layout) |

Everything else is kitty's own, unchanged — worth knowing because this config
deliberately adds nothing on top of them:

| Key | Does |
|---|---|
| `kitty_mod`+<kbd>]</kbd> / <kbd>[</kbd> | Focus the next / previous pane |
| `kitty_mod`+<kbd>f</kbd> / <kbd>b</kbd> | Move this pane forward / back in the layout |
| `kitty_mod`+<kbd>w</kbd> | Close this pane |
| `kitty_mod`+<kbd>r</kbd> | Resize — arrows, then <kbd>Enter</kbd> |
| `kitty_mod`+<kbd>t</kbd>, `kitty_mod`+<kbd>←→</kbd> | New tab, switch tabs |
| `kitty_mod`+<kbd>p</kbd> then <kbd>n</kbd> | Open a `path:line` from Claude's output — in micro, because of `editor micro` |
| `kitty_mod`+<kbd>p</kbd> then <kbd>f</kbd> / <kbd>l</kbd> / <kbd>w</kbd> | Paste a path / line / word from the screen onto your prompt |

This config binds no three-modifier (`Ctrl+Shift+Alt+…`) kitty keys, on
purpose: on a new machine, any kitty key with <kbd>Alt</kbd> in it is kitty's,
not ours. (yazi's <kbd>Alt</kbd>+<kbd>c</kbd> below is a yazi key, not a kitty one.)

## yazi keys (on top of the defaults)

| Key | Does |
|---|---|
| <kbd>C</kbd> | Claude Code in this directory |
| <kbd>Alt</kbd>+<kbd>c</kbd> | Claude Code, seeded with the hovered file |
| <kbd>!</kbd> | Shell here |
| <kbd>G</kbd> | lazygit here |
| <kbd>K</kbd> | Open the kdev workspace in this directory |
| <kbd>Enter</kbd> | Enter directory / open file (smart-enter) |

---

## Layout of this repo

```
kitty/local.conf      kitty options + keybindings   -> ~/.config/kitty/local.conf
kitty/dev.session     the 3-pane layout             -> ~/.config/kitty/dev.session
yazi/*.toml, init.lua yazi config + plugins         -> ~/.config/yazi/
micro/settings.json   editor settings               -> ~/.config/micro/settings.json
bin/kdev              all three panes at once       -> ~/.local/bin/kdev
bin/kpane             add one pane at a time        -> ~/.local/bin/kpane
shell/dev-workspace.bash   y / kdev / e functions   -> sourced from ~/.bashrc
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

**`kdev` opens a second kitty process.** Your running kitty was not started
with `--single-instance`. Harmless; add `-1` to your launcher if it bothers you.

**yazi shows no git signs.** `~/.config/yazi/init.lua` must exist and call
`require("git"):setup{}`. Re-run `./install.sh`.

## License

MIT
