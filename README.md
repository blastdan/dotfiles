# Installation

On a fresh system you need to install the following:

* Git
* Brew
* Stow
* [Zap](https://github.com/zap-zsh/zap)

Git is needed for everyting. Brew will be used to install most dependencies, Stow will be used to manage the symlinks for the dotfiles and zap will be used to manage ZSH packages. Brew isn't essential but recommended, and if you have a different zsh package manager that you prefer go ahead and use it. You will need to make modifications around though.

# Start with a clone

Start by cloning the repository 

``` sh
git clone git@github.com:blastdan/dotfiles.git ~/.dotfiles
```

Clone it into your home directory in a dotfolder of it's own. Navigate to the folder to start

## Why Stow

Stow will just make it easier to symlink our dotfiles for us. Honestly you could do it manually, but this is just easier.

``` sh
stow zsh
```

that will map all the dotfiles found in the zsh folder to your home directory. Just that easy. Do that for all the configuration files that you want in your system.

# dnf history userinstalled

This is the user installed packages from DNF. I'll try and keep them updated. I want to seperate them from project specific to base packages, not sure how that'll go though

* bash-completion-1:2.11-8.fc37.noarch
* distribution-gpg-keys-1.79-1.fc37.noarch
* dnf-utils-4.3.1-1.fc37.noarch
* generic-release-37-0.1.noarch
* git-2.38.1-1.fc37.x86_64
* glibc-langpack-en-2.36-8.fc37.x86_64
* glx-utils-8.4.0-14.20210504git0f9e7d9.fc37.x86_64
* libgcc-12.2.1-4.fc37.x86_64
* mesa-dri-drivers-21.2.3-wsl.fc35.x86_64
* mesa-libGL-21.2.3-wsl.fc35.x86_64
* python3-dnf-plugin-versionlock-4.3.1-1.fc37.noarch
* rsync-3.2.7-1.fc37.x86_64
* stow-2.3.1-9.fc37.noarch
* util-linux-user-2.38.1-1.fc37.x86_64
* vim-enhanced-2:9.0.1006-1.fc37.x86_64
* wget-1.21.3-4.fc37.x86_64
* wslu-4.0.0-1.noarch

# brew leaves

* azure-cli
* bat
* conmon
* crun
* difftastic
* exa
* fd
* fuse-overlayfs
* fzf
* gcc
* gpgme
* k9s
* kind
* krew
* nvm
* ripgrep
* slirp4netns
* tfenv
* tree
* zsh

# zsh plugins

* plug "romkatv/powerlevel10k"
* plug "zsh-users/zsh-autosuggestions"
* plug "hlissner/zsh-autopair"
* plug "zap-zsh/fzf"
* plug "wfxr/forgit"
* plug "ddnexus/fm"
* plug "Aloxaf/fzf-tab"
* plug "zsh-users/zsh-syntax-highlighting"
* plug "jirutka/zsh-shift-select"

# fzf
to install autocompelte and key bindings /home/linuxbrew/.linuxbrew/opt/fzf/install


# Project Specific Install

* MDC
