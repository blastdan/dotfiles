#!/bin/bash
# sync.sh — Re-stow dotfiles and refresh all plugin locks
# Usage: bash sync.sh
set -euo pipefail

command_exists() { command -v "$1" >/dev/null 2>&1; }

ok()   { echo "  [ok] $1"; }
info() { echo " [-->] $1"; }

echo ""
echo "=== dotfiles sync ==="
echo ""

# ── Stow dotfiles ─────────────────────────────────────────────────────────────
info "Stowing dotfiles..."
rm -f ~/.zshrc
stow --dir="$HOME/.dotfiles" --target="$HOME" --restow .
ok "dotfiles stowed"

# ── WSL: copy .wslconfig to Windows home ─────────────────────────────────────
WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
WIN_HOME="/mnt/c/Users/${WIN_USER}"
if [[ -d "$WIN_HOME" ]]; then
    cp ~/.dotfiles/.wslconfig "$WIN_HOME/.wslconfig"
    ok "Copied .wslconfig to $WIN_HOME"
else
    echo "  [!!] Could not find Windows home at $WIN_HOME — copy .wslconfig manually"
fi

# ── sheldon lock ─────────────────────────────────────────────────────────────
if command_exists sheldon; then
    info "Locking sheldon plugins..."
    sheldon lock
    ok "sheldon locked"
fi

# ── oh-my-posh update ────────────────────────────────────────────────────────
if command_exists oh-my-posh; then
    info "Updating oh-my-posh..."
    oh-my-posh upgrade 2>/dev/null || true
    ok "oh-my-posh updated"
fi

# ── tmux plugins ─────────────────────────────────────────────────────────────
if [[ -f "$HOME/.tmux/plugins/tpm/bin/update_plugins" ]]; then
    info "Updating tmux plugins..."
    ~/.tmux/plugins/tpm/bin/update_plugins all
    ok "tmux plugins updated"
fi

# ── neovim plugins ────────────────────────────────────────────────────────────
if command_exists nvim; then
    info "Syncing neovim plugins (headless)..."
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
    ok "neovim plugins synced"
fi

# ── mise runtimes ─────────────────────────────────────────────────────────────
if command_exists mise; then
    info "Installing/updating mise runtimes..."
    mise install
    ok "mise runtimes up to date"
fi

echo ""
echo "=== Sync complete ==="
echo ""
echo "Run: source ~/.zshrc"
echo ""
