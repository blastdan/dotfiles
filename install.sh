#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Homebrew if not already installed
if ! command_exists brew; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew is already installed."
fi

# Starship prompt
if ! command_exists starship; then
    echo "Starship not found. Installing Starship..."
    brew install starship
else
    echo "Starship is already installed."
fi

# Zinit plugin manager
if [ ! -f "$HOME/.local/share/zinit/zinit.git/zinit.zsh" ]; then
    echo "Zinit not found. Installing Zinit..."
    bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
else
    echo "Zinit is already installed."
fi

# The Fuck command corrector
if ! command_exists thefuck; then
    echo "The Fuck not found. Installing The Fuck..."
    brew install thefuck
else
    echo "The Fuck is already installed."
fi

# Eza (improved ls)
if ! command_exists eza; then
    echo "Eza not found. Installing Eza..."
    brew install eza
else
    echo "Eza is already installed."
fi

# Fzf (fuzzy finder)
if ! command_exists fzf; then
    echo "Fzf not found. Installing Fzf..."
    brew install fzf
else
    echo "Fzf is already installed."
fi

# Zoxide (smarter cd)
if ! command_exists zoxide; then
    echo "Zoxide not found. Installing Zoxide..."
    brew install zoxide
else
    echo "Zoxide is already installed."
fi

# Bat (a cat clone with syntax highlighting)
if ! command_exists bat; then
    echo "Bat not found. Installing Bat..."
    brew install bat
else
    echo "Bat is already installed."
fi

# Zellij (terminal workspace manager)
if ! command_exists zellij; then
    echo "Zellij not found. Installing Zellij..."
    brew install zellij
else
    echo "Zellij is already installed."
fi

# Figlet (text rendering)
if ! command_exists figlet; then
    echo "Figlet not found. Installing Figlet..."
    brew install figlet
else
    echo "Figlet is already installed."
fi

# Figlet (text rendering)
if ! command_exists toilet; then
    echo "toilet not found. Installing toilet..."
    brew install toilet
else
    echo "toilet is already installed."
fi

# Lazygit (simple terminal UI for git commands)
if ! command_exists lazygit; then
    echo "Lazygit not found. Installing Lazygit..."
    brew install lazygit
else
    echo "Lazygit is already installed."
fi

# Devbox (for managing development environments)
if ! command_exists devbox; then
    echo "Devbox not found. Installing Devbox..."
    curl -fsSL https://get.jetify.com/devbox | bash
else
    echo "Devbox is already installed."
fi

# direnv
if ! command_exists direnv; then
    echo "direnv not found. Installing direnv..."
    brew install direnv
else
    echo "direnv is already installed."
fi

# nvim
if ! command_exists nvim; then
    echo "Nvim not found. Installing NVim..."
    brew install NVim
else
    echo "NVim is already installed."
fi

# gcloud (for google cloud sdk)
if ! command_exists gcloud; then
    echo "gcloud not found. Installing gcloud..."
    brew install google-cloud-sdk
else
    echo "gcloud is already installed."
fi