#!/bin/sh
[ -f "$HOME/.local/share/zap/zap.zsh" ] && source "$HOME/.local/share/zap/zap.zsh"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# history https://www.soberkoder.com/better-zsh-history/
export HISTFILE=~/.zsh_history
export HISTSIZE=1000000000
export SAVEHIST=1000000000
export HISTTIMEFORMAT="[%F %T] "
setopt appendhistory
setopt INC_APPEND_HISTORY  
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY


# source
autoload -U +X bashcompinit && bashcompinit
autoload -Uz compinit
compinit

plug "$HOME/.config/zsh/kubectl_aliases.sh"
plug "$HOME/.config/zsh/aliases.sh"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

source /home/linuxbrew/.linuxbrew/etc/bash_completion.d/az

#custom functions
source "$HOME/.config/zsh/functions.zsh"
source "$HOME/.config/zsh/functions.timetask.zsh"
source "$HOME/.config/zsh/functions.metrics.zsh"


#plugins
plug "romkatv/powerlevel10k"
plug "zsh-users/zsh-autosuggestions"
plug "hlissner/zsh-autopair"
plug "zap-zsh/fzf"
plug "wfxr/forgit"
plug "ddnexus/fm"
plug "Aloxaf/fzf-tab"
plug "zsh-users/zsh-syntax-highlighting"
plug "jirutka/zsh-shift-select"

#keybinds

bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

#nvm
export NVM_DIR="$HOME/.nvm"
    [ -s "$(brew --prefix)/opt/nvm/nvm.sh" ] && \. "$(brew --prefix)/opt/nvm/nvm.sh" # This loads nvm
    [ -s "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi

export PATH="$PATH:$FORGIT_INSTALL_DIR/bin"
export PATH="${PATH}:${HOME}/.krew/bin"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh