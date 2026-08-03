---
title: "Shell"
description: "Zsh configuration, sheldon plugins, oh-my-posh prompt, all aliases and shell functions."
tags: [shell, zsh, aliases, functions, sheldon, oh-my-posh]
related:
  - title: "Index"
    href: index.md
  - title: "Tmux"
    href: tmux.md
  - title: "Tools"
    href: tools.md
---

# Shell

> **Config entry point:** `~/.dotfiles/.zshrc`
>
> Alias files live in `~/.dotfiles/.alias/` — all are sourced automatically.
> Shell functions live in `~/.dotfiles/.functions/` — all are autoloaded (lazy).

## Zsh Options

### History

| Option                   | Effect                                                  |
| ------------------------ | ------------------------------------------------------- |
| `HISTFILE=~/.hist_zsh`   | Where history is stored                                 |
| `HISTSIZE=100000`        | Lines kept in memory                                    |
| `SAVEHIST=100000`        | Lines written to disk                                   |
| `EXTENDED_HISTORY`       | Records timestamp + duration per command                |
| `HIST_EXPIRE_DUPS_FIRST` | Duplicates are the first to be trimmed                  |
| `HIST_FIND_NO_DUPS`      | `Ctrl-r` won't show duplicate entries                   |
| `HIST_IGNORE_ALL_DUPS`   | Writing a command removes its older copy                |
| `HIST_IGNORE_SPACE`      | Prefix a command with a space to keep it out of history |
| `SHARE_HISTORY`          | All open shells share history in real time              |

### Navigation & Globbing

| Option              | Effect                                                          |
| ------------------- | --------------------------------------------------------------- |
| `AUTO_CD`           | Type a path without `cd` to change to it                        |
| `AUTO_PUSHD`        | Every `cd` silently pushes to the dir stack (`popd` to go back) |
| `PUSHD_IGNORE_DUPS` | No duplicate entries in the dir stack                           |
| `PUSHD_SILENT`      | Dir stack is not printed on each `cd`                           |
| `EXTENDED_GLOB`     | Enables `^`, `#`, `~` glob operators                            |
| `GLOB_DOTS`         | Globs match dotfiles without an explicit leading `.`            |
| `NO_CASE_GLOB`      | Globbing is case-insensitive                                    |

### Completion

| Option             | Effect                                                   |
| ------------------ | -------------------------------------------------------- |
| `COMPLETE_IN_WORD` | Complete from wherever the cursor is, not just the end   |
| `ALWAYS_TO_END`    | After completion the cursor moves to the end of the word |
| `AUTO_MENU`        | Second `Tab` opens the completion menu                   |
| `LIST_PACKED`      | Completion menu uses a compact multi-column layout       |
| `NO_BEEP`          | No bell on failed completion                             |

### Jobs & Safety

| Option                 | Effect                                    |
| ---------------------- | ----------------------------------------- |
| `LONG_LIST_JOBS`       | Background job listings include the PID   |
| `NO_HUP`               | Background jobs survive the shell closing |
| `INTERACTIVE_COMMENTS` | `#` comments work in interactive sessions |
| `RM_STAR_WAIT`         | 10-second pause before `rm *` executes    |

---

## Sheldon — Zsh Plugin Manager

**Config:** `~/.dotfiles/.config/sheldon/plugins.toml`

Sheldon loads plugins at startup via `eval "$(sheldon source)"`. A lockfile is used so plugins are only re-fetched when the config changes.

| Plugin                                       | Purpose                                                     |
| -------------------------------------------- | ----------------------------------------------------------- |
| `zsh-users/zsh-completions`                  | Hundreds of extra completion definitions for common tools   |
| `zsh-users/zsh-autosuggestions`              | Fish-style inline history suggestions — press `→` to accept |
| `zdharma-continuum/fast-syntax-highlighting` | Syntax colouring while you type commands                    |
| `Aloxaf/fzf-tab`                             | Replaces the default completion menu with a live fzf picker |

**Update plugins:** `bash ~/.dotfiles/sync.sh` (runs `sheldon lock` automatically)

---

## oh-my-posh — Prompt

**Config:** `~/.dotfiles/.config/oh-my-posh/config.omp.json`

A two-line powerline prompt using Catppuccin Macchiato colours.

### Left Prompt Segments (left → right)

| Segment | Colour                                                | Shows                                                   |
| ------- | ----------------------------------------------------- | ------------------------------------------------------- |
| OS icon | Mauve                                                 | Penguin (Linux) or Apple (macOS)                        |
| Path    | Blue                                                  | Current directory, max 3 levels deep                    |
| Git     | Teal → Peach (dirty) → Red (diverged) → Green (ahead) | Repo name, branch, staging/working counts, ahead/behind |
| Python  | Yellow                                                | venv name + version (only when inside a virtualenv)     |
| Node    | Green                                                 | Node version (only when `package.json` is present)      |
| kubectl | Sapphire                                              | Current context + namespace                             |

### Right Prompt Segments

| Segment        | Shows                                               |
| -------------- | --------------------------------------------------- |
| Execution time | Duration of last command if it took **> 5 seconds** |
| Exit code      | Green `✓` on success, red `✗ <code>` on failure     |

Second line: `❯` (mauve normally, red on error)

**Upgrade:** `oh-my-posh upgrade` (also run by `sync.sh`)

---

## Aliases

All alias files are sourced only in interactive shells.

### General Development — `.alias/dev`

| Alias     | Expands to                                         |
| --------- | -------------------------------------------------- |
| `nv`      | `nvim`                                             |
| `oc`      | `opencode`                                         |
| `serve`   | `python3 -m http.server` — quick local HTTP server |
| `json`    | `jq .` — pretty-print JSON from stdin              |
| `uuid`    | Print a random UUID                                |
| `myip`    | `curl -s https://ipinfo.io/ip` — show public IP    |
| `weather` | `curl -s wttr.in` — terminal weather               |

### File Listing — `.alias/eza`

`ls`, `ll`, `la` etc. are all overridden with [eza](tools.md#eza). See [Tools → eza](tools.md#eza) for the full table.

### cat — `.alias/bat`

`cat` is overridden with `bat` (syntax highlighting, paging). See [Tools → bat](tools.md#bat).

### cd — `.alias/zoxide`

`cd` is overridden with `z` (zoxide smart jumping). See [Tools → zoxide](tools.md#zoxide).

### System — `.alias/system`

| Alias    | Expands to                                                 |
| -------- | ---------------------------------------------------------- |
| `reload` | `source ~/.zshrc` — reload shell config without restarting |
| `path`   | Print `$PATH` one entry per line                           |
| `ports`  | `ss -tulnp` — show all listening ports                     |
| `df`     | `df -h` — human-readable disk usage                        |
| `free`   | `free -h` — human-readable memory                          |
| `top`    | `htop` (falls back to `top`)                               |
| `mkdir`  | `mkdir -p` — always creates intermediate directories       |
| `cp`     | `cp -iv` — interactive + verbose                           |
| `mv`     | `mv -iv` — interactive + verbose                           |
| `rm`     | `rm -iv` — interactive + verbose                           |

### Git — `.alias/git`

See [Git](git.md) for the complete table.

### Python / uv — `.alias/python`

See [Runtimes → uv](runtimes.md#uv) for the full table.

### Tmux — `.alias/tmux`

See [Tmux → Aliases](tmux.md#aliases) for the full table.

### Kubernetes — `.alias/kubectl`

See [Cloud → kubectl](cloud.md#kubectl) for the full table.

### fzf — `.alias/fzf`

See [Tools → fzf](tools.md#fzf) for configuration and inline functions.

---

## Shell Functions

All functions live in `~/.dotfiles/.functions/` and are autoloaded by name.

### Workspace Launchers

#### `home-dashboard [session]`

The default session launched automatically on every new terminal. See [Tmux → Default Session](tmux.md#default-session--home-dashboard).

- Alias: `th`

#### `tmux-session-name <dir>`

Resolves a directory to the tmux session name that represents it: `<repo>_<branch>` for a worktree or a regular clone, `<repo>` for a bare repo dir itself, `<repo>_<short-sha>` for a detached HEAD, or the sanitised `<basename>` for a non-git directory. Spaces, dots, colons, slashes, and backslashes are replaced with `_`. Branch name comes from git, not from parsing the path.

#### `tmux-layout <layout> <dir> [session_name]`

Starts a tmuxinator layout (`agent`, `review`, or `watch`) rooted at `<dir>`, in a session named via `tmux-session-name` (or the explicit `[session_name]` override). Internally runs `tmuxinator start <layout> -n <name> --no-attach`, then switches the client to it (or attaches if outside tmux). Re-invoking it for a session that already exists reuses that session rather than creating a duplicate. See [Tmux → Workspace Layouts](tmux.md#workspace-layouts) for the layout contents.

- Bound to `Ctrl-a A` (agent), `Ctrl-a G` (review), `Ctrl-a W` (watch)
- Used internally by `gwt-add --layout <name>`

#### `tmux-sessionizer [path]`

fzf-powered project switcher. Searches `~/source` (project directories only — it no longer sweeps all of `$HOME`). Preview shows a directory tree. Each candidate is prefixed with `●` (a tmux session already exists for it) or `○` (none does). Session names are resolved via `tmux-session-name`, not path arithmetic. If already inside tmux, switches the client; otherwise attaches. Cancelling the picker no longer kills your shell.

- Bound to `Ctrl-a T` in tmux
- Alias: `tw`

### File Navigation

#### `y [path]`

Yazi wrapper. Launches [yazi](tools.md#yazi) and `cd`s into whatever directory you were in when you quit (`q`). Without this wrapper, quitting yazi would leave you in the original shell directory.

- Alias: `y`

#### `mkcd <dir>`

`mkdir -p "$dir" && cd "$dir"` — create directory and enter it immediately.

### Cloud

#### `gcloud_swap_profile`

Lists all gcloud configurations (marks the active one). Opens an fzf picker. Activates the selected configuration.

#### `gcloud_generate_profile`

Step-by-step wizard using fzf pickers to select project, account, and region. Prompts for a profile name, then creates and fully configures a new gcloud configuration.

#### `aws_profile [profile-name]`

With no argument: shows the current `$AWS_PROFILE` and opens an fzf picker from `aws configure list-profiles`. With an argument: directly sets `AWS_PROFILE`.

### Utilities

#### `fkill [signal]`

Interactive process killer. Shows a live `ps` list with fzf multi-select. Sends the given signal (default: `-15` SIGTERM) to all selected PIDs.

#### `fman`

fzf man-page browser (defined in `.alias/fzf`). Preview is rendered via `bat --language=man` for syntax highlighting.

#### `tpane list|read|write|key <target> ...`

Reads from and writes to other tmux panes on the current server — the mechanism an agent uses to inspect or drive a different pane. `list` enumerates every pane (id, `session:window.pane`, running command, cwd); `read <target> [--lines N|--all]` prints recent output or full scrollback; `write <target> [--no-enter] <text>` types text (optionally without pressing Enter); `key <target> <key>` sends a key such as `C-c`. `<target>` is a pane id (`%5`) or location (`agent:main.2`). `write` and `key` refuse to target the calling pane. See [Tmux → tpane](tmux.md#tpane--reading-and-writing-other-panes) for the full table.

#### `fenv`

fzf environment variable browser (defined in `.alias/fzf`). Fuzzy-searches all current env vars.

---

## Initialisation Order

The `.zshrc` loads tools in a specific order to avoid conflicts:

1. Homebrew — PATH and shellenv
2. `~/.local/bin` prepended to PATH
3. `fpath` extended with `~/.functions` and `~/.completions`; functions autoloaded
4. **sheldon** — loads zsh plugins
5. **compinit** — cached (skips rebuild if < 24 h old)
6. **Alias files** — sourced after fzf-tab is active
7. **mise** shims — `~/.local/share/mise/shims` on PATH; `secrets.sh` sourced once
8. **oh-my-posh** — initialised
9. **fzf** — shell integration sourced
10. **zoxide** — initialised (`cd` → `z`)
11. **WSL checks** — sets `BROWSER=wslview`; warns if working under `/mnt/*`
12. **Welcome banner** — toilet smslant font

---

_← [Index](index.md) | [Tmux →](tmux.md)_
