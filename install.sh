#!/bin/bash
# install.sh — Bootstrap a new machine with the agent-first dotfiles stack
# Usage: bash install.sh
#
# Run this after cloning the repo:
#   git clone https://github.com/<you>/dotfiles ~/.dotfiles
#   cd ~/.dotfiles && bash install.sh
set -euo pipefail

command_exists() { command -v "$1" >/dev/null 2>&1; }

ok()   { echo "  [ok] $1"; }
info() { echo " [-->] $1"; }
skip() { echo "  [--] $1 already installed, skipping"; }

echo ""
echo "=== dotfiles install ==="
echo ""

# ── apt prerequisites ─────────────────────────────────────────────────────────
info "Installing apt prerequisites..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
    zsh \
    git \
    curl \
    wget \
    build-essential \
    procps \
    file \
    wslu \
    unzip \
    ca-certificates
ok "apt prerequisites installed"

# ── Set zsh as default shell ──────────────────────────────────────────────────
if [[ "$SHELL" != "$(which zsh)" ]]; then
    info "Setting zsh as default shell..."
    chsh -s "$(which zsh)"
    ok "Default shell set to zsh (takes effect on next login)"
else
    skip "zsh already default shell"
fi

# ── mise (runtime manager — replaces pyenv, nvm, etc.) ────────────────────────
if ! command_exists mise; then
    info "Installing mise..."
    curl https://mise.run | sh
    export PATH="$HOME/.local/bin:$PATH"
    ok "mise installed"
else
    skip "mise"
fi

# Activate mise so subsequent steps can use runtimes it manages
eval "$(~/.local/bin/mise activate bash 2>/dev/null || mise activate bash 2>/dev/null || true)"

# ── Homebrew (package manager) ────────────────────────────────────────────────
if ! command_exists brew; then
    info "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    ok "Homebrew installed"
else
    eval "$(brew shellenv 2>/dev/null || true)"
    skip "Homebrew"
fi

# ── sheldon (zsh plugin manager) ─────────────────────────────────────────────
if ! command_exists sheldon; then
    info "Installing sheldon..."
    curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh \
        | bash -s -- --repo rossmacarthur/sheldon --to ~/.local/bin
    ok "sheldon installed"
else
    skip "sheldon"
fi

# ── oh-my-posh (prompt) ───────────────────────────────────────────────────────
if ! command_exists oh-my-posh; then
    info "Installing oh-my-posh..."
    curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin
    ok "oh-my-posh installed"
else
    skip "oh-my-posh"
fi

# ── tmux ─────────────────────────────────────────────────────────────────────
if ! command_exists tmux; then
    info "Installing tmux..."
    brew install tmux
    ok "tmux installed"
else
    skip "tmux"
fi

# tpm (tmux plugin manager)
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    info "Installing tpm..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    ok "tpm installed"
else
    skip "tpm"
fi

# ── neovim ────────────────────────────────────────────────────────────────────
if ! command_exists nvim; then
    info "Installing neovim..."
    brew install neovim
    ok "neovim installed"
else
    skip "neovim"
fi

# ── yazi (file manager) ───────────────────────────────────────────────────────
if ! command_exists yazi; then
    info "Installing yazi..."
    brew install yazi
    ok "yazi installed"
else
    skip "yazi"
fi

# ── uv (Python package manager — replaces poetry/pip) ────────────────────────
if ! command_exists uv; then
    info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    ok "uv installed"
else
    skip "uv"
fi

# ── Core CLI tools ────────────────────────────────────────────────────────────
# Format: "brew-formula:binary-name"  (binary-name used for the command_exists check)
BREW_TOOLS=(
    "ripgrep:rg"
    "fd:fd"
    "fzf:fzf"
    "bat:bat"
    "eza:eza"
    "zoxide:zoxide"
    "lazygit:lazygit"
    "gh:gh"
    "gum:gum"
    "stow:stow"
    "jq:jq"
    "git-delta:delta"
    "htop:htop"
    "figlet:figlet"
    "toilet:toilet"
    "kubectl:kubectl"
    "derailed/k9s/k9s:k9s"
)

for entry in "${BREW_TOOLS[@]}"; do
    formula="${entry%%:*}"
    binary="${entry##*:}"
    if ! command_exists "$binary"; then
        info "Installing $formula..."
        brew install "$formula"
        ok "$binary installed"
    else
        skip "$binary"
    fi
done

# ── OpenCode (AI coding agent) ────────────────────────────────────────────────
if ! command_exists opencode; then
    info "Installing opencode..."
    curl -fsSL https://opencode.ai/install | bash
    ok "opencode installed"
else
    skip "opencode"
fi

# ── Google Cloud SDK ─────────────────────────────────────────────────────────
if ! command_exists gcloud; then
    info "Installing gcloud SDK..."
    brew install google-cloud-sdk
    ok "gcloud installed"
else
    skip "gcloud"
fi

# ── Stow dotfiles ─────────────────────────────────────────────────────────────
info "Stowing dotfiles..."
rm -f ~/.zshrc
stow --dir="$HOME/.dotfiles" --target="$HOME" .
ok "dotfiles stowed"

# ── mise secrets bootstrap ────────────────────────────────────────────────────
if [[ ! -f "$HOME/.config/mise/secrets.sh" ]]; then
    info "Creating empty secrets.sh (fill in after gcloud auth login)..."
    cp "$HOME/.config/mise/secrets.sh.example" "$HOME/.config/mise/secrets.sh"
    ok "secrets.sh created from example"
fi

# ── mise runtimes ─────────────────────────────────────────────────────────────
info "Installing mise runtimes (python, node)..."
mise install
ok "mise runtimes installed"

# ── tmux plugins ─────────────────────────────────────────────────────────────
info "Installing tmux plugins..."
~/.tmux/plugins/tpm/bin/install_plugins
ok "tmux plugins installed"

# ── neovim plugins ────────────────────────────────────────────────────────────
info "Installing neovim plugins (headless)..."
nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
ok "neovim plugins installed"

# ── sheldon lock ─────────────────────────────────────────────────────────────
info "Locking sheldon plugins..."
sheldon lock
ok "sheldon locked"

echo ""
echo "=== Install complete ==="
echo ""
echo "Next steps:"
echo "  1. Log out and back in (or: exec zsh) for zsh to take effect"
echo "  2. Run: source ~/.zshrc"
echo "  3. Authenticate GCP: gcloud auth login"
echo "     Then fill in ~/.config/mise/secrets.sh with your secrets"
echo "  4. Restart WSL to apply .wslconfig: run 'wsl --shutdown' from PowerShell"
echo "  5. In a new tmux session: Ctrl-a I to finish installing tmux plugins"
echo ""
