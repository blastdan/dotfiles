# ============================================================
# PATH
# ============================================================

# Cache eval-based init scripts. Invalidates when the binary is newer than the cache.
# Usage: _zrc_init <name> <binary> [args...]
_zrc_init() {
  local name="$1"; shift
  local cache="$HOME/.cache/zsh-init/${name}.zsh"
  local bin="$1"
  [[ -x "$bin" ]] || bin="${commands[$name]:-$(command -v $name 2>/dev/null)}"
  [[ -z "$bin" ]] && return 1
  if [[ ! -f "$cache" ]] || [[ "$bin" -nt "$cache" ]]; then
    mkdir -p "${cache:h}"
    "$@" > "$cache" 2>/dev/null
  fi
  source "$cache"
}

# Homebrew — cache shellenv (brew Ruby startup is expensive in WSL2)
() {
  local brew_bin
  for brew_bin in /home/linuxbrew/.linuxbrew/bin/brew /usr/local/bin/brew /opt/homebrew/bin/brew; do
    [[ -x "$brew_bin" ]] || continue
    local cache="$HOME/.cache/zsh-init/brew.zsh"
    if [[ ! -f "$cache" ]] || [[ "$brew_bin" -nt "$cache" ]]; then
      mkdir -p "${cache:h}"
      "$brew_bin" shellenv > "$cache"
    fi
    source "$cache"
    break
  done
}

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

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
# Filter broken symlinks out of fpath before compinit to avoid "no such file"
# warnings (e.g. Docker Desktop's completion symlink when Docker isn't running).
fpath=(${^fpath}(N))       # (N) glob qualifier: silently drops non-existent paths

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
if (( ${+commands[mise]} )); then
  # Cache mise activation and strip the eager _mise_hook call on line 60.
  # The hook is already registered as precmd, so it fires before the first
  # prompt — calling it again during sourcing costs ~400ms for no benefit.
  local _mise_cache="$HOME/.cache/zsh-init/mise.zsh"
  local _mise_bin="${commands[mise]}"
  if [[ ! -f "$_mise_cache" ]] || [[ "$_mise_bin" -nt "$_mise_cache" ]]; then
    mkdir -p "${_mise_cache:h}"
    mise activate zsh | grep -v '^_mise_hook$' > "$_mise_cache"
  fi
  source "$_mise_cache"
  [[ -f "$HOME/.config/mise/secrets.sh" ]] && source "$HOME/.config/mise/secrets.sh"
else
  echo "[dotfiles] mise not installed — run: bash ~/.dotfiles/install.sh" >&2
fi

# ============================================================
# PROMPT — Oh My Posh (Catppuccin Macchiato)
# ============================================================
# Not cached — oh-my-posh init generates a fresh POSH_SESSION_ID (used to
# name the per-session prompt cache). Hardcoding it would cause cross-terminal
# cache collisions (stale git status bleeding between windows).
if (( ${+commands[oh-my-posh]} )); then
  eval "$(oh-my-posh init zsh --config "$HOME/.config/oh-my-posh/config.omp.json")"
else
  echo "[dotfiles] oh-my-posh not installed — run: bash ~/.dotfiles/install.sh" >&2
fi

# ============================================================
# TOOLS
# ============================================================

# fzf
(( ${+commands[fzf]} )) && _zrc_init fzf fzf --zsh

# zoxide (smarter cd — must come after compinit)
(( ${+commands[zoxide]} )) && _zrc_init zoxide zoxide init zsh

# navi (interactive cheatsheet — Ctrl+G)
export NAVI_PATH="$HOME/.config/navi/cheats"
(( ${+commands[navi]} )) && _zrc_init navi navi widget zsh

# atuin (searchable shell history — replaces Ctrl+R)
(( ${+commands[atuin]} )) && _zrc_init atuin atuin init zsh

# GCP org context — restore GCP_ORG_ID if exactly one org is saved (default)
# Use `gcloud_swap_org` to add/remove/switch orgs.
() {
  local _org_file="${HOME}/.config/gcloud/active_org"
  [[ -f "$_org_file" ]] || return
  local lines=("${(@f)$(<"$_org_file")}")
  (( ${#lines} == 1 )) && export GCP_ORG_ID="${lines[1]%%:*}"
}

# ============================================================
# WSL
# ============================================================

# Set browser to wslview
(( ${+commands[wslview]} )) && export BROWSER=wslview

# PulseAudio: prefer WSLg socket; fall back to user-space daemon if it's dead.
# Socket file existence is sufficient to set PULSE_SERVER — skip the pactl probe
# (each pactl info call costs ~100ms in WSL2 due to subprocess fork overhead).
if [[ -S /mnt/wslg/runtime-dir/pulse/native ]]; then
  export PULSE_SERVER=unix:/mnt/wslg/runtime-dir/pulse/native
elif [[ -S /mnt/wslg/PulseServer ]]; then
  export PULSE_SERVER=unix:/mnt/wslg/PulseServer
else
  export PULSE_SERVER=unix:/run/user/${UID}/pulse/native
  if ! pactl info &>/dev/null 2>&1; then
    env -u PULSE_SERVER pulseaudio --start 2>/dev/null
  fi
fi

# Notify on long-running commands (threshold: 10 seconds)
# Uses wsl-notify-send.exe — only fires when WSL interop is available.
if (( ${+commands[wsl-notify-send.exe]} )); then
  __notify_threshold=10
  __notify_cmd=""
  __notify_start=0

  __notify_preexec() {
    __notify_cmd="$1"
    __notify_start=$SECONDS
  }

  __notify_precmd() {
    local elapsed=$(( SECONDS - __notify_start ))
    if (( elapsed >= __notify_threshold )) && [[ -n "$__notify_cmd" ]]; then
      local category="shell"
      local prefix=""
      if [[ -n "$TMUX" ]]; then
        local session window
        session=$(tmux display-message -p '#S')
        window=$(tmux display-message -p '#I:#W')
        category="tmux: $session"
        prefix="[$window] "
      fi
      wsl-notify-send.exe --category "$category" "${prefix}${__notify_cmd} (${elapsed}s)"
    fi
    __notify_cmd=""
  }

  add-zsh-hook preexec __notify_preexec
  add-zsh-hook precmd  __notify_precmd
fi

# alias-tips: after a command that an existing alias would have shortened, print
# the alias once. Interactive only — hooks never fire in the non-interactive
# shells that agents and tmux popups use, and the guard makes that explicit.
# Each tip shows at most 3 times, at most hourly, then retires. `alias-tips` to
# inspect, `alias-tips --reset` to re-arm, `alias-tips --off` for this shell.
if [[ -o interactive ]]; then
  zmodload -F zsh/datetime p:EPOCHSECONDS 2>/dev/null
  _alias_tips_preexec() { alias-tips _preexec "$1" }
  _alias_tips_precmd()  { alias-tips _precmd }
  add-zsh-hook preexec _alias_tips_preexec
  add-zsh-hook precmd  _alias_tips_precmd
fi

# onefetch: greet with a repo summary card when entering a git project directory
if (( ${+commands[onefetch]} )); then
  _onefetch_chpwd() {
    [[ -d .git ]] && onefetch --no-merges 2>/dev/null
  }
  add-zsh-hook chpwd _onefetch_chpwd
fi

# Warn once per login shell when working on the Windows filesystem (slow I/O)
if [[ -o login ]] && [[ "$PWD" == /mnt/* ]]; then
  echo "Warning: You are on the Windows filesystem ($PWD). Performance will be slow. Consider working under ~/." >&2
fi

# ============================================================
# TMUX AUTO-START
# ============================================================
# On every interactive login shell: if not already inside tmux,
# attach to the existing 'home' session (continuum may have restored
# it) or create a fresh home-dashboard.
if [[ -o interactive ]] && [[ -o login ]] && [[ -z "$TMUX" ]] && (( ${+commands[tmux]} )); then
  home-dashboard
fi

# ============================================================
# WELCOME BANNER
# ============================================================
# Fire once after the first prompt so the shell is ready immediately.
if (( ${+commands[toilet]} )); then
  _banner_precmd() {
    toilet -d /home/linuxbrew/.linuxbrew/share/figlet/fonts -f smslant -F gay -F border -t "Player 1 - Get Ready *"
    add-zsh-hook -d precmd _banner_precmd
    unfunction _banner_precmd
  }
  add-zsh-hook precmd _banner_precmd
fi

export PATH="/usr/local/bin:$PATH"