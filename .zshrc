# ============================================================
# PATH
# ============================================================
# Homebrew — dynamic so it works on Linux and macOS
if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
elif [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export PATH="$HOME/.local/bin:$PATH"

# ============================================================
# COMPLETIONS & FUNCTIONS
# ============================================================
fpath=($HOME/.functions $fpath)
fpath=($HOME/.completions $fpath)

# Load all autoload-style functions (lazy — body loaded on first call)
for funcfile in $HOME/.functions/*(.N); do
  autoload -Uz ${funcfile:t}
done

# ============================================================
# HISTORY
# ============================================================
export HISTFILE="$HOME/.hist_zsh"
export HISTSIZE=100000
export SAVEHIST=$HISTSIZE

setopt EXTENDED_HISTORY          # Save timestamp and duration with each entry
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicates first when trimming
setopt HIST_FIND_NO_DUPS         # Don't show duplicates when searching
setopt HIST_IGNORE_ALL_DUPS      # Remove older duplicate entry if a new one is added
setopt HIST_IGNORE_DUPS          # Don't record consecutive duplicates
setopt HIST_IGNORE_SPACE         # Don't record entries that start with a space
setopt HIST_SAVE_NO_DUPS         # Don't write duplicates to the history file
setopt SHARE_HISTORY             # Share history across all sessions in real time

# ============================================================
# SHELL BEHAVIOUR
# ============================================================

# Directory navigation
setopt AUTO_CD                   # Type a path to cd into it without 'cd'
setopt AUTO_PUSHD                # Every cd pushes to the dir stack
setopt PUSHD_IGNORE_DUPS         # No duplicate entries in the dir stack
setopt PUSHD_SILENT              # Don't print the stack on every cd

# Globbing
setopt EXTENDED_GLOB             # Enable ^, #, ~ glob operators
setopt GLOB_DOTS                 # Globs match dotfiles without leading '.'
setopt NO_CASE_GLOB              # Case-insensitive globbing

# Completion
setopt COMPLETE_IN_WORD          # Complete from cursor position, not just end of word
setopt ALWAYS_TO_END             # Move cursor to end after completion
setopt AUTO_MENU                 # Show completion menu on second Tab press
setopt LIST_PACKED               # Completion menu uses less vertical space
setopt NO_BEEP                   # No terminal bell on completion misses

# Job control
setopt LONG_LIST_JOBS            # Show PID when backgrounding a job
setopt NO_HUP                    # Background jobs keep running when shell closes

# UX
setopt INTERACTIVE_COMMENTS      # Allow # comments in interactive shell
setopt RM_STAR_WAIT              # Pause 10s before executing rm *

# ============================================================
# SHELL PLUGINS — sheldon
# ============================================================
if command -v sheldon >/dev/null 2>&1; then
  eval "$(sheldon source)"
else
  echo "[dotfiles] sheldon not installed — run: bash ~/.dotfiles/install.sh" >&2
fi

# compinit after plugins so sheldon-provided completions are included.
# Cache the dumpfile and only re-scan fpath once per day.
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# Source all alias files (after sheldon so fzf-tab is active)
for _aliasfile in $HOME/.alias/*(.N); do
  source "$_aliasfile"
done
unset _aliasfile

# ============================================================
# RUNTIMES & SECRETS — mise
# ============================================================
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
else
  echo "[dotfiles] mise not installed — run: bash ~/.dotfiles/install.sh" >&2
fi

# ============================================================
# PROMPT — Oh My Posh (Catppuccin Macchiato)
# ============================================================
if command -v oh-my-posh >/dev/null 2>&1; then
  eval "$(oh-my-posh init zsh --config '$HOME/.config/oh-my-posh/config.omp.json')"
else
  echo "[dotfiles] oh-my-posh not installed — run: bash ~/.dotfiles/install.sh" >&2
fi

# ============================================================
# TOOLS
# ============================================================

# fzf
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

# zoxide (smarter cd — must come after compinit)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# ============================================================
# WSL
# ============================================================

# Set browser to wslview
if command -v wslview >/dev/null 2>&1; then
  export BROWSER=wslview
fi

# Warn once per login shell when working on the Windows filesystem (slow I/O)
if [[ -o login ]] && [[ "$PWD" == /mnt/* ]]; then
  echo "Warning: You are on the Windows filesystem ($PWD). Performance will be slow. Consider working under ~/." >&2
fi

# ============================================================
# WELCOME BANNER
# ============================================================
if command -v toilet >/dev/null 2>&1; then
  # Point toilet at figlet's font dir so smslant is found
  export TOILET_FONT_PATH="/home/linuxbrew/.linuxbrew/share/figlet"
  toilet -f smslant -F gay -F border -t "Player 1 - Get Ready *"
fi
