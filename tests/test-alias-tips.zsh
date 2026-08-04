#!/bin/zsh
source "${0:A:h}/_harness.zsh"

# Run alias-tips in a controlled shell: fixed alias set, and a FRESH state dir per
# call by default. Sharing one state dir let an earlier case consume a tip's
# hourly slot, which made later cases fail for reasons unrelated to what they
# were testing.
# NOTE: every call site is `out=$(tips ...)`, which runs in a command-substitution
# SUBSHELL. An incrementing counter for the state dir therefore never reached the
# parent, so every case silently reused the same dir and later cases tripped over
# an earlier case's hourly throttle. mktemp works correctly in a subshell.
_tips_run() {  # _tips_run <state-dir> <script>
  # Write the case to a file rather than interpolating into `zsh -c "..."`.
  # Nested quoting there mangled cases containing flags like `-s`, producing
  # failures that looked like code bugs but were the harness's own.
  mkdir -p "$1" 2>/dev/null
  local f="$1/case.zsh"
  {
    print -r -- "fpath=($HOME/.dotfiles/.functions \$fpath)"
    print -r -- 'autoload -Uz alias-tips'
    print -r -- 'zmodload -F zsh/datetime p:EPOCHSECONDS'
    print -r -- "alias gs='git status'"
    print -r -- "alias gl='git log --oneline --graph --decorate -20'"
    print -r -- "alias grep='grep --color=auto'"
    print -r -- "alias bad='foo | bar'"
    print -r -- "$2"
  } > "$f"
  # Strip ANSI so assertions compare plain text.
  XDG_STATE_HOME="$1" zsh "$f" 2>&1 | sed $'s/\033\\[[0-9;]*m//g'
}
tips() {   # isolated: fresh state every call
  local d; d=$(mktemp -d "$SCRATCH/xdg-XXXXXX")
  _tips_run "$d" "$*"
}
tips_in() { # explicit state dir, for the throttle/retire cases
  local d="$1"; shift
  _tips_run "$d" "$*"
}

# ── the core rule: expansion must be a token-aligned prefix ───────────────────
out=$(tips "alias-tips _preexec 'git status'; alias-tips _precmd")
assert_contains "$out" "gs" "exact match tips the alias"

out=$(tips "alias-tips _preexec 'git status -s'; alias-tips _precmd")
assert_contains "$out" "gs" "alias + extra args still tips (gs -s is equivalent)"

# gl adds four flags, so `git log` is NOT equivalent to gl. Must stay silent —
# suggesting it would change behaviour behind the user's back.
out=$(tips "alias-tips _preexec 'git log'; alias-tips _precmd")
assert_eq "" "$out" "does NOT tip when the alias would add flags you didn't ask for"

# Token alignment: 'git statusfoo' must not match 'git status'.
out=$(tips "alias-tips _preexec 'git statusfoo'; alias-tips _precmd")
assert_eq "" "$out" "prefix must be token-aligned, not substring"

# Already used an alias → nothing to teach.
out=$(tips "alias-tips _preexec 'gs'; alias-tips _precmd")
assert_eq "" "$out" "silent when you already used an alias"

# Unrelated command → silent.
out=$(tips "alias-tips _preexec 'echo hello'; alias-tips _precmd")
assert_eq "" "$out" "silent for commands with no matching alias"

# Aliases with pipes/subshells are excluded as unreliable to prefix-match.
out=$(tips "alias-tips _preexec 'foo | bar'; alias-tips _precmd")
assert_eq "" "$out" "skips aliases whose value contains a pipe"

# Same-name aliases (grep='grep --color=auto') save nothing → excluded.
out=$(tips "alias-tips _preexec 'grep --color=auto x'; alias-tips _precmd")
assert_eq "" "$out" "skips aliases that save no keystrokes"

# ── throttle ──────────────────────────────────────────────────────────────────
# Within the hour, a second identical miss must stay quiet.
out=$(tips "
  alias-tips _preexec 'git status'; alias-tips _precmd
  alias-tips _preexec 'git status'; alias-tips _precmd
")
assert_eq "1" "$(print -r -- "$out" | grep -c 'tip:')" \
  "second miss within the hour is throttled"

# After 3 shows it retires. Force the counter past the cap, and last=0 so the
# hourly gap is long satisfied — proving retirement, not throttling, is the cause.
retire_dir="$SCRATCH/xdg-retire"
mkdir -p "$retire_dir/alias-tips"
printf 'gs\t3\t0\n' > "$retire_dir/alias-tips/seen"
out=$(tips_in "$retire_dir" "alias-tips _preexec 'git status'; alias-tips _precmd")
assert_eq "" "$out" "retired after 3 shows, even with the hour elapsed"

# --reset re-arms it, in that same retired state.
out=$(tips_in "$retire_dir" "alias-tips --reset gs; alias-tips _preexec 'git status'; alias-tips _precmd")
assert_contains "$out" "tip:" "--reset re-arms a retired tip"

# ── the agent-shell constraint ────────────────────────────────────────────────
# Hooks must never fire in a non-interactive shell, which is what Claude Code and
# tmux popups use. This is the property the user asked for explicitly.
out=$(zsh -c '
  source ~/.dotfiles/.zshrc 2>/dev/null
  print -r -- "MARKER"
  git --version >/dev/null 2>&1
' 2>&1 | grep -c 'tip:')
assert_eq "0" "$out" "no tips in a NON-interactive shell (agent shells stay clean)"

# And the hook registration itself is guarded.
assert_ok "zshrc guards the hook on [[ -o interactive ]]" -- \
  grep -q 'if \[\[ -o interactive \]\]' "$HOME/.dotfiles/.zshrc"

# ── plumbing ──────────────────────────────────────────────────────────────────
assert_fail "unknown option rejected" -- \
  zsh -c "fpath=($HOME/.dotfiles/.functions \$fpath); autoload -Uz alias-tips; alias-tips --bogus"
out=$(tips "alias-tips --help")
assert_contains "$out" "alias-tips" "--help renders"

cleanup_fixtures
test_summary
