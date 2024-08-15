#!/bin/bash

function install_zsh() {
  # Check if zsh is already installed
  if command -v zsh &> /dev/null; then
    echo "zsh is already installed."
  else
    # Install zsh using the package manager
    sudo apt install zsh  # Replace with your package manager if needed (e.g., yum, dnf)
  fi

  # Add zsh to the list of valid shells
  echo "/bin/zsh" | sudo tee -a /etc/shells > /dev/null

  # Set zsh as the default shell for the current user
  sudo chsh -s $(which zsh) $USER

  echo "zsh installed and set as default shell. Please log out and log back in for changes to take effect."
}

function install_brew() {
    echo "Installing Homebrew"

    # Download and run Homebrew installation script
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    echo 'export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"' >> ~/.zshrc

    source ~/.zshrc
}

function install_core() {

    echo "Installing core applicaitons"

    # Update apt
    sudo apt update

    # Install required dependencies
    sudo apt install build-essential git curl file procps libstdc++6
}

install_core
install_zsh
install_brew