# dotfiles

Agent-first developer environment for WSL2 — optimized for working with AI coding agents (OpenCode), tmux, and neovim. Catppuccin Macchiato everywhere.

## Philosophy

- **Agent-safe**: interactive-only aliases guarded with `[[ -o interactive ]]` so AI agent shells stay clean
- **No secrets in git**: secrets flow through GCP Secret Manager → mise environments → shell
- **Beginner-friendly**: which-key in nvim, status bar hints in tmux, `?` for help everywhere
- **VSCode muscle memory preserved**: `Ctrl-s` save, `Ctrl-p` find files, familiar keybinds in nvim

## Quick start

```bash
git clone https://github.com/<you>/dotfiles ~/.dotfiles
cd ~/.dotfiles
bash install.sh
source ~/.zshrc
```

Then in a new tmux session, press `Ctrl-a I` to install tmux plugins.

## Tool stack

| Category | Tool | Replaces |
|---|---|---|
| Shell plugins | [sheldon](https://sheldon.cli.rs) | zinit |
| Prompt | [oh-my-posh](https://ohmyposh.dev) | starship |
| Runtime manager | [mise](https://mise.jdx.dev) | pyenv + nvm + direnv |
| Python packages | [uv](https://docs.astral.sh/uv) | poetry + pip |
| Terminal multiplexer | [tmux](https://github.com/tmux/tmux) | zellij |
| Editor | [neovim](https://neovim.io) + kickstart.nvim | NvChad / VSCode |
| File manager | [yazi](https://yazi-rs.github.io) | ranger |
| `ls` | [eza](https://github.com/eza-community/eza) | ls |
| `cat` | [bat](https://github.com/sharkdp/bat) | cat |
| `grep` | [ripgrep](https://github.com/BurntSushi/ripgrep) | grep |
| `find` | [fd](https://github.com/sharkdp/fd) | find |
| `cd` | [zoxide](https://github.com/ajeetdsouza/zoxide) | cd |
| Git TUI | [lazygit](https://github.com/jesseduffield/lazygit) | — |
| AI coding agent | [OpenCode](https://opencode.ai) | — |

## Key bindings

### tmux (prefix: `Ctrl-a`)

| Key | Action |
|---|---|
| `Ctrl-a ?` | Cheatsheet popup |
| `Ctrl-a \|` | Split vertical |
| `Ctrl-a -` | Split horizontal |
| `Ctrl-a hjkl` | Navigate panes (also works across nvim splits) |
| `Ctrl-a c` | New window |
| `Ctrl-a 1-9` | Switch window |
| `Ctrl-a s` | tmux-sessionizer (fzf project picker) |

### neovim (`<leader>` = Space)

| Key | Action |
|---|---|
| `<leader>` | which-key hint menu |
| `<leader>ff` | Find file (Telescope) |
| `<leader>fg` | Live grep |
| `<leader>e` | File explorer (neo-tree) |
| `<leader>ca` | Code action |
| `<leader>rn` | Rename symbol |
| `<leader>fm` | Format file |
| `gd` | Go to definition |
| `gr` | References |
| `Ctrl-s` | Save |

### Shell functions

| Command | Action |
|---|---|
| `tmux-sessionizer` | fzf-based project switcher |
| `agent-workspace` | Open 3-pane tmux layout for AI coding |
| `review-workspace` | Open diff/review tmux layout |
| `mkcd <dir>` | Create directory and cd into it |
| `y` | Open yazi (cds to selected dir on exit) |
| `gcloud_swap_profile` | fzf switch GCP profile (shows current) |
| `gcloud_generate_profile` | Create new GCP profile with fzf pickers |

## Secrets

Secrets are never stored in git. The flow is:

```
GCP Secret Manager (<gcp-secrets-project>)
    ↓ gcloud secrets versions access
~/.config/mise/secrets.sh  (gitignored, loaded by mise)
    ↓ mise env
Shell environment (GITHUB_PAT, etc.)
```

Setup:
```bash
# Copy the example and fill in your values
cp ~/.config/mise/secrets.sh.example ~/.config/mise/secrets.sh
# Or load from GCP:
gcloud secrets versions access latest --secret=github-pat --project=<gcp-secrets-project>
```

## WSL notes

- `.wslconfig` sets `memory=12GB, processors=8, swap=8GB, appendWindowsPath=false`
- `sync.sh` auto-copies `.wslconfig` to `C:\Users\<you>\`
- Apply with `wsl --shutdown` from PowerShell
- Clipboard uses OSC 52 (works in Windows Terminal)
- Browser links open with `wslview`
- Avoid working under `/mnt/c/` — use WSL filesystem for performance

## Scripts

```bash
bash install.sh   # Bootstrap a new machine (installs all tools + plugins)
bash sync.sh      # Re-stow dotfiles + update all plugins
```

## OpenCode agents

| Agent | Use |
|---|---|
| `build` (default) | General coding, full tool access |
| `plan` | Planning only — asks before any edit or shell command |
| `dotfiles` | Dotfiles specialist — shell, tmux, nvim, tool configs |
| `explore` | Read-only research subagent |
| `general` | Multi-step research subagent |

Custom commands: `/plan-approve`, `/review-diff`, `/commit-message`, `/workspace-setup`

## Structure

```
~/.dotfiles/
├── .zshrc                        # Shell entry point (~70 lines, clean)
├── .alias/                       # Alias files (sourced by .zshrc)
├── .functions/                   # Shell functions (sourced by .zshrc)
├── .gitconfig                    # Git config
├── .config/
│   ├── mise/                     # Runtime + secrets management
│   ├── sheldon/                  # Zsh plugin manager
│   ├── oh-my-posh/               # Prompt theme (Catppuccin Macchiato)
│   ├── tmux/                     # tmux config + Catppuccin theme
│   ├── nvim/                     # Neovim (kickstart-based, single init.lua)
│   ├── yazi/                     # File manager (Catppuccin Macchiato)
│   ├── bat/                      # Cat replacement theme
│   ├── lazygit/                  # Git TUI theme
│   ├── k9s/                      # Kubernetes TUI theme
│   └── opencode/                 # AI agent config + custom commands
├── install.sh                    # Bootstrap script
└── sync.sh                       # Re-stow + update plugins
```
