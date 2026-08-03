---
title: "Git"
description: "Git aliases, worktree workflow, interactive fzf-powered git functions, lazygit TUI, and GitHub CLI reference."
tags: [git, worktrees, lazygit, gh, aliases, fzf]
related:
  - title: "Index"
    href: index.md
  - title: "Tools"
    href: tools.md
  - title: "Maintenance"
    href: maintenance.md
---

# Git

> **Alias config:** `~/.dotfiles/.alias/git`
>
> **lazygit config:** `~/.dotfiles/.config/lazygit/config.yml`
>
> **gh config:** `~/.dotfiles/.config/gh/config.yml`

Three layers of git tooling: plain aliases for speed, fzf-powered interactive functions for complex operations, and lazygit for a full visual TUI.

---

## Git Aliases

### Status & Diff

| Alias | Command | Description |
|-------|---------|-------------|
| `gs` | `git status` | Working tree status |
| `gd` | `git diff` | Unstaged changes |
| `gds` | `git diff --staged` | Staged changes (what will be committed) |

### Log

| Alias | Command | Description |
|-------|---------|-------------|
| `gl` | `git log --oneline --graph --decorate -20` | Last 20 commits, compact graph |
| `gla` | `git log --oneline --graph --decorate --all` | Full graph for all branches |

### Branching

| Alias | Command | Description |
|-------|---------|-------------|
| `gco <branch>` | `git checkout` | Switch branch |
| `gcb <name>` | `git checkout -b` | Create and switch to new branch |

### Staging & Committing

| Alias | Command | Description |
|-------|---------|-------------|
| `ga <file>` | `git add` | Stage specific file(s) |
| `gaa` | `git add -A` | Stage everything |
| `gc` | `git commit` | Commit (opens editor) |
| `gcm "<msg>"` | `git commit -m` | Commit with inline message |
| `gca` | `git commit --amend` | Amend last commit |

### Push & Pull

| Alias | Command | Description |
|-------|---------|-------------|
| `gp` | `git push` | Push to remote |
| `gpf` | `git push --force-with-lease` | Force push (safe — fails if remote has new commits) |
| `gpl` | `git pull` | Pull from remote |
| `gf` | `git fetch --all --prune` | Fetch all remotes, prune deleted branches |

### Rebase & Stash

| Alias | Command | Description |
|-------|---------|-------------|
| `grb <branch>` | `git rebase` | Rebase onto branch |
| `grbi HEAD~n` | `git rebase -i` | Interactive rebase (squash, edit, reorder) |
| `gst` | `git stash` | Stash working tree changes |
| `gstp` | `git stash pop` | Apply and remove top stash |

---

## Git Worktrees

> **Why worktrees?** A worktree lets you check out multiple branches simultaneously as separate directories. No stashing, no context-switching — `main/` and `feature-x/` are just two folders open at the same time.
>
> **Repo layout** (`~/source/repos/<org>/<repo>/`):
> ```
> ~/source/repos/<org>/my-repo/          ← bare repo (git data only)
> ~/source/repos/<org>/my-repo/main/     ← main branch worktree
> ~/source/repos/<org>/my-repo/feature/  ← feature branch worktree
> ```

### Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `gwt` | `git worktree` | Base command |
| `gwtl` | `git worktree list` | List all worktrees for current repo |
| `gwtc <url>` | `gwt-clone` | Bare-clone a repo, ready for worktrees |
| `gwti <name>` | `gwt-init` | Init a **new** repo with bare worktree layout |
| `gwta <branch>` | `gwt-add` | Add a worktree only — tmux is opt-in (see below) |
| `gwtf` | `gwt` | fzf picker — switch between worktrees |
| `gwtrm <path>` | `git worktree remove` | Remove a worktree directory |
| `gwtrmf <path>` | `git worktree remove --force` | Force-remove an unclean worktree |
| `gwtpr` | `git worktree prune` | Clean up stale worktree metadata |

### Cloning a repo for worktrees — `gwt-clone`

Use this instead of `git clone` for any repo you plan to use worktrees with:

```bash
gwt-clone https://github.com/<org>/my-repo
# → clones bare to ~/source/repos/<org>/my-repo/
# → creates ~/source/repos/<org>/my-repo/main/ automatically

gwt-clone https://github.com/<org>/my-repo MyOrg
# → explicit org name override
```

The org is inferred from the GitHub URL automatically. The resulting structure is a bare repo with an initial `main` (or `master`) worktree already checked out.

### Initialising a new repo — `gwt-init`

Use this instead of `git init` when starting a brand-new project you want to use with worktrees:

```bash
gwt-init my-project              # org guessed from existing ~/source/repos/ siblings
gwt-init my-project <org> # explicit org name
```

Creates `~/source/repos/<org>/my-project/` as a bare repo with an empty initial commit and a `main/` worktree already checked out. Identical structure to `gwt-clone` so all other worktree commands work the same way.

### Adding a worktree — `gwt-add`

From anywhere inside the repo or any of its worktrees. **Tmux is opt-in** — by default `gwt-add` only creates the worktree (and branch, with `--new`); it does not touch tmux at all.

```bash
gwta feature-x                        # checkout existing branch as a worktree — no tmux
gwta feature-x --new                  # create branch + worktree — no tmux
gwta feature-x --session              # worktree + a plain shell tmux session
gwta feature-x --layout agent         # worktree + agent layout (nvim | claude | shell)
gwta feature-x --layout review        # worktree + review layout (lazygit | claude)
gwta feature-x --layout watch         # worktree + watch layout (claude | test cmd | git status)
gwta feature-x --agent                # shorthand for --layout agent
```

| Flag | Effect |
|------|--------|
| *(none)* | Worktree (+ branch, with `--new`) only. No tmux session created. |
| `--new` | Create the branch with `git worktree add -b` before checking it out. |
| `--session` | Open a plain shell tmux session rooted at the worktree. |
| `--layout <name>` | Launch a tmuxinator layout: `agent`, `review`, `watch`, or `none` (synonym for `--session`). |
| `--agent` | Backwards-compatible shorthand for `--layout agent`. |

This is a **behaviour change**: earlier versions always opened a tmux session for you. Now you must ask for one explicitly with `--session` or `--layout`.

Sessions (when created) are named `<repo>_<branch>` via `tmux-session-name` — e.g. `my-repo_feature-x` — with slashes, dots, colons, and spaces in the branch name sanitised to underscores. `tmux-sessionizer` (`tw`) and `gwt` also surface worktrees, using the same naming.

Run `gwta --help` for the full flag/layout reference.

### Switching between worktrees — `gwt` / `gwtf`

```bash
gwt       # fzf picker: shows all worktrees with git log preview, switches tmux session
gwt --cd  # same picker, but just cd into the selected worktree (no tmux)
gwtl      # plain list of all worktrees and their HEAD commits
```

Each entry in the `gwt` picker is prefixed with `●` or `○`: `●` means a tmux session already exists for that worktree (switching to it reattaches), `○` means none does (selecting it creates one, named via `tmux-session-name`). Cancelling out of the picker (`Esc`/`Ctrl-c`) no longer kills your shell.

### Day-to-day workflow

```bash
# 1a. Clone an existing repo (once per repo)
gwt-clone https://github.com/<org>/my-repo

# 1b. OR start a brand-new project
gwt-init my-project <org>

# 2. Start a new piece of work
cd ~/source/repos/<org>/my-repo/main
gwta my-feature --new --agent   # creates branch + worktree + launches agent layout

# 3. Switch between open worktrees
gwt                             # fzf picker → switches tmux session

# 4. Clean up after merging
gwtrm ~/source/repos/<org>/my-repo/my-feature
gwtpr                           # prune stale metadata
```

### Converting an existing regular clone

If you have an existing `git clone` and want to migrate to the bare-repo worktree layout:

```bash
# Back up, then re-clone as bare
mv ~/source/repos/Org/my-repo ~/source/repos/Org/my-repo.bak
gwt-clone https://github.com/Org/my-repo
# verify it looks right, then remove the backup
rm -rf ~/source/repos/Org/my-repo.bak
```

---

Interactive git operations powered by fzf. These replace common multi-step workflows with a single command.

### `gcof` — Interactive Branch Checkout

Browse all local and remote branches sorted by most recently committed. Preview shows the last commits on that branch.

```bash
gcof
```

- `Enter` — checkout selected branch
- `Ctrl-c` — cancel

### `gadd` — Interactive Staged Add

Browse all unstaged/untracked files. Preview shows the diff for each file.

```bash
gadd
```

- `Tab` — toggle selection (multi-select)
- `Enter` — stage all selected files

### `gshow` — Browse Commit Log

Fuzzy search the full git log. Preview shows the complete diff for each commit.

```bash
gshow
```

- `Enter` — open full commit diff in `bat`/`less` for reading

### `gstashf` — Interactive Stash Browser

Browse all stash entries. Preview shows the stash diff.

```bash
gstashf
```

- `Enter` — apply selected stash

---

## lazygit — Git TUI

> **Alias:** `lz`
>
> **Config:** `~/.dotfiles/.config/lazygit/config.yml`

lazygit is a full terminal UI for git. Launch it with `lz` from any repo.

**Configured with:**
- `delta` as the diff pager (syntax-highlighted diffs with Catppuccin Macchiato theme)
- Catppuccin Macchiato UI colours

### lazygit Panels

```
┌──────────────────┬───────────────────────────────────┐
│ Status / Files   │                                   │
├──────────────────┤          Diff / Preview           │
│ Branches         │                                   │
├──────────────────┤                                   │
│ Commits          │                                   │
├──────────────────┤                                   │
│ Stash            │                                   │
└──────────────────┴───────────────────────────────────┘
```

### Navigation

| Key | Action |
|-----|--------|
| `h` / `l` | Switch between panels (left/right) |
| `j` / `k` | Move up/down within a panel |
| `Tab` | Next panel |
| `Shift-Tab` | Previous panel |
| `[` / `]` | Previous/next tab within a panel |
| `q` | Quit lazygit |

### Files Panel

| Key | Action |
|-----|--------|
| `Space` | Stage/unstage file |
| `a` | Stage/unstage all files |
| `Enter` | View file diff |
| `d` | Discard changes in file |
| `e` | Open in `nvim` |
| `i` | Add to `.gitignore` |
| `c` | Commit staged changes |
| `w` | Commit without hooks |
| `A` | Amend last commit |

### Branches Panel

| Key | Action |
|-----|--------|
| `Space` | Checkout branch |
| `n` | New branch |
| `d` | Delete branch |
| `r` | Rebase onto selected branch |
| `M` | Merge into current branch |
| `f` | Fast-forward branch |
| `p` | Push branch |

### Commits Panel

| Key | Action |
|-----|--------|
| `Space` | Checkout commit |
| `Enter` | View commit files |
| `r` | Reword commit message |
| `e` | Edit commit (drops into interactive rebase) |
| `d` | Drop commit |
| `f` | Fixup into parent commit |
| `s` | Squash with parent |
| `p` | Pick (interactive rebase) |
| `ctrl-j/k` | Move commit up/down |

### Stash Panel

| Key | Action |
|-----|--------|
| `Space` | Apply stash |
| `Enter` | View stash diff |
| `g` | Pop stash (apply + remove) |
| `d` | Drop stash entry |
| `n` | Create new stash |

### Global Keys

| Key | Action |
|-----|--------|
| `?` | Show keybind help for current panel |
| `x` | Open command menu (extra options) |
| `Ctrl-r` | Switch repository (recent list) |
| `+` | Maximise current panel |
| `_` | Minimise current panel |
| `@` | Open commit graph popup |
| `:` | Run custom `git` command |

---

## GitHub CLI — `gh`

> **Config:** `~/.dotfiles/.config/gh/config.yml`

The `gh` CLI interacts with GitHub directly from the terminal.

### Configured Alias

| Alias | Command |
|-------|---------|
| `gh co` | `gh pr checkout` — checkout a PR branch by number or URL |

### Common Workflows

```bash
# Pull requests
gh pr list                        # list open PRs
gh pr create                      # create a PR (interactive)
gh pr view                        # view current branch's PR
gh pr checkout 123                # checkout PR #123
gh co 123                         # same via alias

# Issues
gh issue list                     # list open issues
gh issue create                   # create an issue
gh issue view 42                  # view issue #42

# Repos
gh repo clone owner/repo          # clone a repo
gh repo view                      # open repo in browser

# Workflow runs
gh run list                       # list recent CI runs
gh run view                       # view current run
```

**Authentication:** `gh` is configured to use HTTPS with credentials provided via `gh auth git-credential` (set in `.gitconfig`). Login with `gh auth login` if needed.

---

*← [Tools](tools.md) | [Index](index.md) | [Cloud →](cloud.md)*
