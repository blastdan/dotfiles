export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
export PATH="$HOME/.config/emacs/bin:$PATH"

# Directory containing function files and completions
fpath=($HOME/.functions $fpath)
fpath=($HOME/.completions $fpath)

autoload -U compinit && compinit

export HISTFILE="$HOME/.hist_zsh"
export HISTSIZE=5000000
export SAVEHIST=$HISTSIZE

# HISTORY
setopt EXTENDED_HISTORY          # Write the history file in the ':start:elapsed;command' format.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire a duplicate event first when trimming history.
setopt HIST_FIND_NO_DUPS         # Do not display a previously found event.
setopt HIST_IGNORE_ALL_DUPS      # Delete an old recorded event if a new event is a duplicate.
setopt HIST_IGNORE_DUPS          # Do not record an event that was just recorded again.
setopt HIST_IGNORE_SPACE         # Do not record an event starting with a space.
setopt HIST_SAVE_NO_DUPS         # Do not write a duplicate event to the history file.
setopt SHARE_HISTORY             # Share history between all sessions.
# END HISTORY

# Load all functions in the directory
for funcfile in $HOME/.functions/*(.N); do
  autoload -Uz ${funcfile:t}
done

# autoload aliases
autoload_aliases

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk

### Zinit Loading

# Global
zinit light zsh-users/zsh-completions
zinit light Aloxaf/fzf-tab

# UI enhancements
zinit light zdharma-continuum/fast-syntax-highlighting

# Programming
zinit light darvid/zsh-poetry

##$ End Zinit Loading

# Check if wslview is installed
if command -v wslview >/dev/null 2>&1; then
  # WSL: set the browser to wslview
  export BROWSER=wslview
fi


# Devbox
if [ -e /home/daniel/.nix-profile/etc/profile.d/nix.sh ]; then . /home/daniel/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer

# Direnv
eval "$(direnv hook zsh)"

# Starship
eval "$(starship init zsh)"

# Set up fzf
source <(fzf --zsh)

# Set up zoxide
eval "$(zoxide init zsh)"export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"

# Setup ZelliJ
if [[ -z "$ZELLIJ" ]]; then
    if [[ "$ZELLIJ_AUTO_ATTACH" == "true" ]]; then
        zellij attach -c
    else
        zellij
    fi

    if [[ "$ZELLIJ_AUTO_EXIT" == "true" ]]; then
        exit
    fi
fi


if command -v toilet >/dev/null 2>&1; then
  fonts=$(figlet -I 2)
  # WSL: set the browser to wslview
  toilet -f "smslant" -d $fonts -F gay -F border -t "Player 1 - Get Ready *"
fi