---
title: "Tmux"
description: "Tmux session management, all keybindings, pane navigation, copy mode, workspace layouts, and plugin reference."
tags: [tmux, multiplexer, keybindings, sessions, plugins]
related:
  - title: "Index"
    href: index.md
  - title: "Shell"
    href: shell.md
  - title: "Neovim"
    href: neovim.md
---

# Tmux

> **Config:** `~/.dotfiles/.config/tmux/tmux.conf`
>
> **Prefix:** `Ctrl-a` (replaces the default `Ctrl-b`)

Tmux is the terminal multiplexer — it lets you split a single terminal window into multiple panes, keep sessions alive after disconnecting, and orchestrate multi-tool workspaces with a single keystroke.

---

## Concepts

| Term | Meaning |
|------|---------|
| **Session** | A persistent workspace, survives terminal close |
| **Window** | A tab within a session (shows in the status bar) |
| **Pane** | A split within a window |
| **Prefix** | `Ctrl-a` — press it before any tmux command key |

---

## Keybindings

### Session & Window Management

| Key | Action |
|-----|--------|
| `Ctrl-a c` | New window (inherits current path) |
| `Ctrl-a 1–9` | Switch to window by number |
| `Ctrl-a s` | Session picker (tree view of all sessions + windows) |
| `Ctrl-a T` | **tmux-sessionizer** — fzf project picker, creates/switches named session |
| `Ctrl-a $` | Rename current session |
| `Ctrl-a ,` | Rename current window |
| `Ctrl-a X` | Kill current window |

`tmux-sessionizer` now only sweeps project directories under `~/source` (not all of `$HOME`), shows a `●`/`○` marker per candidate (`●` = a tmux session already exists for it, `○` = none), and delegates session naming to `tmux-session-name` (`<repo>_<branch>`, not path arithmetic). Cancelling out of the picker no longer kills your shell. `gwt` (the worktree picker, see [git.md](git.md)) uses the same markers and naming.

### Pane Management

| Key | Action |
|-----|--------|
| `Ctrl-a \|` | Split pane **vertically** (side by side, inherits path) |
| `Ctrl-a -` | Split pane **horizontally** (top/bottom, inherits path) |
| `Ctrl-a x` | Kill current pane |
| `Ctrl-a f` | Toggle pane **fullscreen** (zoom) |

### Pane Navigation (no prefix required)

These pass through seamlessly to Neovim splits via `vim-tmux-navigator`:

| Key | Action |
|-----|--------|
| `Ctrl-h` | Move focus **left** |
| `Ctrl-j` | Move focus **down** |
| `Ctrl-k` | Move focus **up** |
| `Ctrl-l` | Move focus **right** |

### Pane Resizing

| Key | Action |
|-----|--------|
| `Ctrl-a H` | Resize pane **left** by 5 cells |
| `Ctrl-a J` | Resize pane **down** by 5 cells |
| `Ctrl-a K` | Resize pane **up** by 5 cells |
| `Ctrl-a L` | Resize pane **right** by 5 cells |

`Ctrl-a K` is resize-up. It was previously dead (bound twice, shadowed by the session killer) — that conflict is fixed, and the killer now lives on `Ctrl-a Q`.

### Copy Mode (vi bindings)

Enter copy mode with `Ctrl-a Enter` to scroll and select text.

| Key | Action |
|-----|--------|
| `Ctrl-a Enter` | Enter copy mode |
| `v` | Begin character selection |
| `V` | Select entire line |
| `Ctrl-v` | Toggle rectangle selection |
| `y` | Copy selection to clipboard (via xclip / OSC 52) |
| `Y` | Copy current line |
| `Escape` | Cancel / exit copy mode |
| `Ctrl-a p` | Paste from clipboard buffer |
| `Ctrl-a P` | Pick from buffer history (list of past copies) |

### Config

| Key | Action |
|-----|--------|
| `Ctrl-a r` | Reload `tmux.conf` without restarting |
| `Ctrl-a Ctrl-a` | Send the prefix keystroke to the inner session (useful when nesting tmux) |

### Workspace Launchers (popup)

| Key | Action |
|-----|--------|
| `Ctrl-a ?` | Open keybind **cheatsheet** popup |
| `Ctrl-a S` | **fzf tmuxinator picker** — fuzzy-select any layout and launch it |
| `Ctrl-a Q` | **Session killer** — fzf multi-select picker, kill one or more sessions |
| `Ctrl-a A` | Launch `agent` layout (nvim + claude + shell) via `tmux-layout` |
| `Ctrl-a G` | Launch `review` layout (lazygit + claude) via `tmux-layout` |
| `Ctrl-a W` | Launch `watch` layout (claude + test command + git status) via `tmux-layout` |

All three layout keys start the layout in a session named `<repo>_<branch>` (via `tmux-session-name`/`tmux-layout`, not the raw directory name) and reuse an existing session of that name instead of creating a duplicate.

`multi` was removed — there is no 4-pane grid layout anymore. All layouts run `claude`, not `opencode`.

### Notifications

See [notifications.md](notifications.md) for the full OSC 9 setup (requires Ghostty).

| Key | Action |
|-----|--------|
| `Ctrl-a m` | **tmux-notify** — monitor current pane, toast when the command completes |
| `Ctrl-a Alt-m` | Monitor + jump to previous window |
| `Ctrl-a M` | **Belongs to tmux-notify** — cancels the active pane monitor. The plugin hard-binds this key and ignores the `@tnotify-cancel-key` setting, so `Ctrl-a M` must never be rebound to a layout or anything else. |

---

## Default Session — Home Dashboard

Every new terminal automatically starts (or re-attaches to) the `home` session.

```
┌─────────────────┬────────────────────────┐
│                 │                        │
│   yazi          │    shell  ← focus      │
│   ~/source      │                        │
│   (40%)         ├────────────────────────┤
│                 │   git-overview         │
│                 │   (recent commits      │
│                 │    across all repos)   │
└─────────────────┴────────────────────────┘
```

**How it works:**
- On every login shell, if you're not already inside tmux, `home-dashboard` is called automatically
- If the `home` session already exists (restored by tmux-continuum), it attaches to it instead of creating a duplicate
- The git overview pane shows the last 3 commits + dirty/staged status for every repo found under `~/source`

**Alias:** `th` — re-launch or jump back to the home dashboard at any time

---

## Aliases

Defined in `~/.dotfiles/.alias/tmux`:

| Alias | Command |
|-------|---------|
| `ta <name>` | `tmux attach -t <name>` |
| `tl` | `tmux list-sessions` |
| `tk <name>` | `tmux kill-session -t <name>` |
| `tn <name>` | `tmux new-session -s <name>` |
| `tw` | `tmux-sessionizer` (fzf project picker) |
| `th` | `home-dashboard` (default session: yazi + shell + git overview) |
| `mux` | `tmuxinator` |
| `muxs <layout>` | `tmuxinator start <layout>` |
| `muxl` | `tmuxinator list` — list all layouts |
| `muxe <layout>` | `tmuxinator edit <layout>` |
| `muxn <layout>` | `tmuxinator new <layout>` |
| `muxk <layout>` | `tmuxinator stop <layout>` |

---

## Workspace Layouts

Workspace layouts are managed by **[tmuxinator](https://github.com/tmux-plugins/tmuxinator)**. Layout files live in `~/.dotfiles/.config/tmuxinator/`. Launch via hotkey (`Ctrl-a A` / `G` / `W`), `gwt-add --layout <name>`, or the fzf picker (`Ctrl-a S`).

All three layouts are started through `tmux-layout <layout> <dir> [session_name]`, which starts tmuxinator with `-n <name> --no-attach` in a correctly-named session (`<repo>_<branch>`, resolved via `tmux-session-name`) and then switches/attaches. Re-invoking it for a session that already exists reuses that session instead of creating a duplicate. There is no `multi` layout anymore, and every layout runs `claude`, not `opencode`.

### `agent` / `Ctrl-a A`

```
┌─────────────────┬──────────────────┐
│                 │   claude    (60%)│
│   nvim   (60%)  ├──────────────────┤
│                 │   shell     (40%)│
└─────────────────┴──────────────────┘
```

### `review` / `Ctrl-a G`

```
┌─────────────────┬──────────────┐
│  lazygit  (60%) │  claude (40%)│
└─────────────────┴──────────────┘
```

### `watch` / `Ctrl-a W`

```
┌─────────────────┬──────────────────────┐
│                 │  $WATCH_TEST_CMD     │
│   claude (60%)  ├──────────────────────┤
│                 │  watch -n 5 'git     │
│                 │  status -sb'         │
└─────────────────┴──────────────────────┘
```

`$WATCH_TEST_CMD` runs whatever test/build command you export before launching; when it's unset the pane is a plain shell.

### Tmuxinator Layout Files

| Layout | File | Description |
|--------|------|-------------|
| `agent` | `tmuxinator/agent.yml` | nvim (left) + claude (top-right) + shell (bottom-right) |
| `review` | `tmuxinator/review.yml` | lazygit (left, 60%) + claude (right, 40%) |
| `watch` | `tmuxinator/watch.yml` | claude (left) + `$WATCH_TEST_CMD` (top-right, plain shell if unset) + `watch -n 5 'git status -sb'` (bottom-right) |

Layouts start in `$PWD` (or the worktree path when launched via `gwt-add`). Add new layouts with `muxn <name>`.

---

## Plugins

Managed by [tpm](https://github.com/tmux-plugins/tpm) (Tmux Plugin Manager).

| Plugin | Purpose |
|--------|---------|
| `tmux-plugins/tmux-sensible` | Sane defaults: faster key repeat, UTF-8, larger history |
| `tmux-plugins/tmux-resurrect` | Manually save/restore sessions across reboots (`Ctrl-a Ctrl-s` / `Ctrl-a Ctrl-r`) |
| `tmux-plugins/tmux-continuum` | Auto-saves session every **15 minutes**; auto-restores on tmux start |
| `rickstaa/tmux-notify` | OSC 9 desktop notification when a monitored pane's command finishes |

### Plugin Management

| Command | Action |
|---------|--------|
| `Ctrl-a I` | Install plugins listed in `tmux.conf` |
| `Ctrl-a U` | Update all plugins |
| `Ctrl-a Alt-u` | Uninstall plugins not in config |

Plugin directory: `~/.dotfiles/.config/tmux/plugins/`

---

## `tpane` — reading and writing other panes

`tpane` lets an agent (or you) inspect and drive other panes on the current tmux server, without attaching to them.

| Command | Action |
|---------|--------|
| `tpane list` | List every pane: id, `session:window.pane`, running command, cwd |
| `tpane read <target> [--lines N]` | Print the pane's recent output (default 100 lines) |
| `tpane read <target> --all` | Print the full scrollback |
| `tpane write <target> <text>` | Type text into the pane and press Enter |
| `tpane write <target> --no-enter <text>` | Type without pressing Enter |
| `tpane key <target> <key>` | Send a key such as `C-c`, `Escape`, `Up` |

`<target>` is a pane id (`%5`) or a location (`agent:main.2`) — run `tpane list` first to discover valid targets; never guess a pane id. `write` and `key` both refuse to target the calling pane, so a session can't feed its own output back into itself.

---

## Status Bar

The bottom status bar shows (Catppuccin Macchiato theme):
- Left: session name
- Centre: window list (active window highlighted)
- Right: date + time

The status bar displays a hint for `Ctrl-a ?` to remind you the cheatsheet is always one keypress away.

---

## Session Persistence

`tmux-continuum` saves your session state every 15 minutes automatically. After a reboot:

1. Start tmux — sessions, windows, and panes are restored
2. You may need to rerun commands in each pane (processes are not restored, only the layout)

To manually save: `Ctrl-a Ctrl-s`
To manually restore: `Ctrl-a Ctrl-r`

---

*← [Shell](shell.md) | [Index](index.md) | [Neovim →](neovim.md)*
