# CLAUDE.md

Agent-facing operational guide for working on this dotfiles repo. For user-facing docs see `README.md` and `docs/`.

## What this repo is

An agent-first developer environment for WSL2 managed with **GNU stow**. Every file here is symlinked into `$HOME` by stow. The repo is designed for AI coding agent workflows — OpenCode and Claude Code are first-class tools.

## How deployment works (stow)

**Never edit files directly in `$HOME`. Always edit here in `~/.dotfiles`, then restow.**

```bash
# Restow everything (safe to run repeatedly):
stow --restow . --target="$HOME"

# Or run the full sync (restow + update all plugins):
bash sync.sh
```

Stow creates symlinks for every file/dir in this repo into `$HOME`, preserving the directory structure. Files listed in `.stow-local-ignore` are not linked:

```
.git  .gitignore  install.sh  README.md  sync.sh
.config/mise/secrets.sh.example  .wslconfig
```

`.wslconfig` is excluded from stow; `sync.sh` copies it manually to `C:\Users\<user>\` via `/mnt/c/`.

## Conventions

### Alias files (`.alias/`)

- One file per tool/category. Sourced alphabetically by `.zshrc`.
- Aliases that **replace standard tools** (`cat`, `ls`, `cd`, etc.) must be guarded so agent shells don't break:
  ```zsh
  if [[ -o interactive ]]; then
    alias cat='bat'
  fi
  ```
- Plain shortcut aliases (`gs='git status'`, `nv='nvim'`) don't need the guard.
- First line: a brief comment explaining the file's scope.

### Function files (`.functions/`)

- One function per file. File name = function name (autoloaded by `.zshrc`).
- **Line 2 comment format** — used by the `cheat` browser as the description:
  ```zsh
  #!/bin/zsh
  # funcname: one-line description
  ```
- Functions are interactive by design. No interactive guard needed (autoload is only triggered in interactive shells).
- Use `fzf` for any user selection; prefer `gum` for confirmation dialogs.

### Config files (`.config/`)

- One subdirectory per tool. All files within are stowed.
- Prefer TOML/YAML/JSON for tool configs — check whether the tool expects a specific format.
- Neovim config lives entirely in `.config/nvim/init.lua` (single-file, lazy.nvim managed).
- Tmuxinator layouts live in `.config/tmuxinator/*.yml`.

### Secrets

- **Never commit secrets.** They live in `~/.config/mise/secrets.sh` (gitignored, not stowed).
- Reference secrets as env vars: mise loads `secrets.sh` and injects them into shell.
- The example template is at `.config/mise/secrets.sh.example`.
- Secret flow: `GCP Secret Manager → secrets.sh → mise env → shell`.

### WSL patterns

- Links/files: use `wslview <url>` not `xdg-open`.
- Desktop notifications: `wsl-notify-send.exe --category 'MyTool' 'message'`.
- Clipboard: OSC 52 (works in Windows Terminal). Avoid `xclip`/`xsel`.
- Never redirect work to `/mnt/c/` — performance is terrible. Work under `~/` (WSL FS).

## Common tasks

### Add an alias

Create or append to the relevant `.alias/<tool>` file:
```zsh
# .alias/dev
alias serve='python3 -m http.server'
```
Then `source ~/.zshrc` or open a new shell.

### Add a shell function

Create `.functions/<funcname>`:
```zsh
#!/bin/zsh
# funcname: brief description shown by `cheat`
funcname() {
  # implementation
}
```
Then `source ~/.zshrc` (autoload picks it up automatically).

### Add a Neovim plugin

Edit `.config/nvim/init.lua` — add to the `require('lazy').setup({ ... })` table:
```lua
{ 'author/plugin-name', opts = {} },
```
Verify: `nvim --headless "+Lazy! sync" +qa`

### Add a tmux keybind

Edit `.config/tmux/tmux.conf`:
```tmux
bind-key <key> run-shell "some-command"
```
Also add a matching entry in `.functions/tmux-cheatsheet` so `Ctrl-a ?` stays up to date.
Verify: `tmux source ~/.config/tmux/tmux.conf`

### Add a tmuxinator layout

Create `.config/tmuxinator/<name>.yml`:
```yaml
name: <name>
root: <%= @args[0] || "~" %>
windows:
  - editor:
      layout: main-vertical
      panes:
        - nvim
        - opencode
        - ''
```
Reference it in `gwt-add` via `--layout <name>` or in `proj-new`.

### Add an OpenCode agent

Edit `.config/opencode/opencode.json` — add to the `agents` array:
```json
{
  "name": "agent-name",
  "description": "What it does.",
  "mode": "primary",
  "model": "claude-sonnet-4-6",
  "permission": { "edit": "allow", "bash": { "rm -rf *": "deny", "*": "allow" } }
}
```

### Add an OpenCode custom command

Create `.config/opencode/command/<name>.md` with a markdown prompt. The command becomes available as `/<name>` inside OpenCode.

## Verification

After any change, run the relevant check:

| Change | Verify with |
|--------|-------------|
| Alias / function | `source ~/.zshrc` |
| Any dotfile | `bash sync.sh` (restow + plugin updates) |
| Neovim plugin | `nvim --headless "+Lazy! sync" +qa` |
| Tmux config | `tmux source ~/.config/tmux/tmux.conf` |
| New tmux plugin | `Ctrl-a I` inside tmux (tpm install) |
| Mise runtime | `mise install` |

## Key file index

| File | Purpose |
|------|---------|
| `.zshrc` | Shell entry point — loads sheldon, aliases, functions, mise, omp, fzf, zoxide |
| `.alias/` | Alias files, one per tool |
| `.functions/` | Shell functions, one per file, autoloaded |
| `.gitconfig` | Git user, delta pager, credential helper |
| `.config/nvim/init.lua` | Full Neovim config (kickstart + lazy.nvim) |
| `.config/tmux/tmux.conf` | Tmux config, prefix = Ctrl-a |
| `.config/tmuxinator/` | Named workspace layouts (agent, review, multi) |
| `.config/opencode/opencode.json` | OpenCode agents + MCP servers + permissions |
| `.config/opencode/command/` | OpenCode custom slash commands |
| `.config/mise/config.toml` | Managed runtimes (Python 3.13, Node 22, Terraform) |
| `.claude/settings.json` | Claude Code settings (model, permissions, hooks) |
| `.serena/project.yml` | Serena MCP config for this repo |
| `install.sh` | Bootstrap new machine (not stowed) |
| `sync.sh` | Restow + update all plugins (not stowed) |

## Worktree workflow

Projects are organized as bare repos under `~/source/repos/<org>/<repo>/`, with each branch as a separate worktree directory. Key commands:

| Command | Action |
|---------|--------|
| `gwt-clone <url>` | Bare-clone repo, create initial worktree |
| `gwt-add <branch> --new --layout agent` | New branch + worktree + agent tmux session |
| `gwt` | fzf picker — switch between worktrees |
| `proj-new` | Interactive 6-step project init wizard |
| `tmux-sessionizer` | fzf project picker → named tmux session |

Tmux session naming: `<repo>_<branch>` (spaces/dots/slashes → underscores).

## Reading and writing tmux panes

`tpane` lets an agent inspect and drive other panes in the current tmux server.

| Command | Action |
|---------|--------|
| `tpane list` | List every pane: id, `session:window.pane`, running command, cwd |
| `tpane read <target> [--lines N]` | Print the pane's recent output (default 100 lines) |
| `tpane read <target> --all` | Print the full scrollback |
| `tpane write <target> <text>` | Type text into the pane and press Enter |
| `tpane write <target> --no-enter <text>` | Type without pressing Enter |
| `tpane key <target> <key>` | Send a key such as `C-c`, `Escape`, `Up` |

`<target>` is a pane id (`%5`) or a location (`agent:main.2`) — run `tpane list`
to get both. Start with `tpane list` to discover targets; never guess a pane id.

`write` and `key` refuse to target the calling pane, so an agent cannot feed its
own output back to itself.

## Documentation

Full reference docs live in `docs/`:

- `docs/shell.md` — Zsh, aliases, all functions
- `docs/tmux.md` — All keybindings, layouts, plugins
- `docs/neovim.md` — Plugins, LSP, all keybindings
- `docs/git.md` — Git aliases, fzf-git, worktree workflow
- `docs/opencode.md` — Agents, MCP servers, custom commands
- `docs/tools.md` — bat, eza, fzf, zoxide, yazi
- `docs/cloud.md` — gcloud, AWS, kubectl
- `docs/runtimes.md` — mise, uv, Node
- `docs/notifications.md` — WSL toast notifications
- `docs/maintenance.md` — Bootstrap, sync, secrets, WSL config

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
