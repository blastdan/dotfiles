#!/bin/zsh
# _harness.zsh: assertion helpers and git/tmux fixtures for dotfiles tests

SCRATCH="/tmp/claude-1000/-home-daniel/725b72c6-4ee3-4143-bc95-1f6535996795/scratchpad/dotfiles-tests"

# ── isolate tmux ──────────────────────────────────────────────────────────────
# Tests must never touch the real tmux server. They create sessions, spawn real
# nvim/claude/lazygit panes, and — when $TMUX is set — the functions under test
# take their `switch-client` branch, which yanks the user's attached client into
# a test session mid-run.
#
# TMUX_TMPDIR redirects tmux to a private server, and because it is exported it
# is inherited by everything: the functions autoloaded here, and the ones run as
# standalone scripts (tmux run-shell / display-popup targets). That matters —
# per-call `tmux -L` would not cover the functions under test, which call `tmux`
# directly in ~39 places.
#
# Unsetting TMUX/TMUX_PANE makes those functions take their `attach-session`
# branch rather than `switch-client`, so no real client is ever redirected. The
# attach fails harmlessly with no controlling terminal; tests assert on session
# state, not on attach success. Tests needing a valid $TMUX_PANE (tpane's
# self-pane guard) set it from a pane on THIS server.
#
# The socket dir is deliberately short and NOT under $SCRATCH: unix socket paths
# cap around 104 chars, and $SCRATCH plus tmux's own `/tmux-<uid>/default`
# suffix comes to ~116.
export TMUX_TMPDIR="${TMPDIR:-/tmp}/dotfiles-test-tmux-${UID}"
mkdir -p "$TMUX_TMPDIR"
unset TMUX TMUX_PANE

# Start the private server eagerly with a keepalive session. Several test files
# guard themselves with `[[ -z "$TMUX" ]] && ! tmux has-session` and SKIP when no
# server is reachable — on a freshly-isolated server that guard would fire and
# silently skip ~34 assertions while run-all still printed "all passed".
tmux new-session -ds _harness_keepalive -c /tmp 2>/dev/null

TESTS_RUN=0
TESTS_FAILED=0
FIXTURE_DIRS=()
FIXTURE_SESSIONS=()

# Load the repo's functions as autoloadable functions.
fpath=("$HOME/.dotfiles/.functions" $fpath)
for _f in "$HOME"/.dotfiles/.functions/*(.N); do
  autoload -Uz "${_f:t}"
done

_pass() { TESTS_RUN=$((TESTS_RUN+1)); print -r -- "  ok   — $1" }
_fail() {
  TESTS_RUN=$((TESTS_RUN+1)); TESTS_FAILED=$((TESTS_FAILED+1))
  print -r -- "  FAIL — $1"
  [[ -n "$2" ]] && print -r -- "         $2"
}

assert_eq() {
  local expected="$1" actual="$2" label="$3"
  [[ "$expected" == "$actual" ]] \
    && _pass "$label" \
    || _fail "$label" "expected '$expected', got '$actual'"
}

assert_contains() {
  local haystack="$1" needle="$2" label="$3"
  [[ "$haystack" == *"$needle"* ]] \
    && _pass "$label" \
    || _fail "$label" "'$needle' not found in: $haystack"
}

assert_ok() {   # assert_ok "label" -- cmd args...
  local label="$1"; shift; [[ "$1" == "--" ]] && shift
  if "$@" >/dev/null 2>&1; then _pass "$label"
  else _fail "$label" "expected exit 0, got $? from: $*"; fi
}

assert_fail() { # assert_fail "label" -- cmd args...
  local label="$1"; shift; [[ "$1" == "--" ]] && shift
  if "$@" >/dev/null 2>&1; then _fail "$label" "expected non-zero exit from: $*"
  else _pass "$label"; fi
}

# ── fixtures ──────────────────────────────────────────────────────────────────
make_bare_repo() {
  local name="$1" root="$SCRATCH/$1"
  mkdir -p "$root"
  # Seed a normal repo, then convert to the bare-with-worktrees layout.
  local seed="$SCRATCH/.seed-$name"
  mkdir -p "$seed"
  git -C "$seed" init -q -b main
  git -C "$seed" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
  git clone -q --bare "$seed" "$root/.bare" 2>/dev/null
  # Bare repo lives directly at $root so worktrees nest under it.
  mv "$root/.bare"/* "$root"/ 2>/dev/null
  rmdir "$root/.bare" 2>/dev/null
  FIXTURE_DIRS+=("$root" "$seed")
  print -r -- "$root"
}

make_worktree() {
  local bare="$1" branch="$2" wt="$1/$2"
  git -C "$bare" worktree add -q -b "$branch" "$wt" 2>/dev/null \
    || git -C "$bare" worktree add -q "$wt" "$branch" 2>/dev/null
  print -r -- "$wt"
}

track_session() { FIXTURE_SESSIONS+=("$1") }

# ── waiters ───────────────────────────────────────────────────────────────────
# tmuxinator spawns panes asynchronously, and a pane's current command only
# becomes e.g. `claude` once the binary has actually started. Fixed `sleep`s
# raced that and produced intermittent single-assertion failures. Poll instead.

# wait_for_session <name> [timeout_s]
wait_for_session() {
  local s="$1" t="${2:-10}" i
  for (( i = 0; i < t * 5; i++ )); do
    tmux has-session -t="$s" 2>/dev/null && return 0
    sleep 0.2
  done
  return 1
}

# wait_for_pane_text <target> <text> [timeout_s] — waits for <text> to appear in
# the pane's visible output. Fixed sleeps raced pane rendering under load: a
# write of 40 lines had not finished drawing when the assertion ran, which failed
# only in full-suite runs, never in isolation.
wait_for_pane_text() {
  local t="$1" want="$2" to="${3:-15}" i
  for (( i = 0; i < to * 5; i++ )); do
    tmux capture-pane -p -t "$t" 2>/dev/null | grep -qF -- "$want" && return 0
    sleep 0.2
  done
  return 1
}

# wait_for_pane_cmd <session> <command> [timeout_s] — waits for any pane in the
# session to be running <command>.
wait_for_pane_cmd() {
  local s="$1" want="$2" t="${3:-20}" i
  for (( i = 0; i < t * 5; i++ )); do
    tmux list-panes -t="$s" -F '#{pane_current_command}' 2>/dev/null \
      | grep -qxF -- "$want" && return 0
    sleep 0.2
  done
  return 1
}

cleanup_fixtures() {
  local s d
  for s in "${FIXTURE_SESSIONS[@]}"; do tmux kill-session -t="$s" 2>/dev/null; done
  # Kill the whole private server — catches sessions no test remembered to
  # track. Safe only because TMUX_TMPDIR points at our own socket, never the
  # user's; guard it so a lost TMUX_TMPDIR can't kill their real server.
  if [[ -n "$TMUX_TMPDIR" && "$TMUX_TMPDIR" == */dotfiles-test-tmux-* ]]; then
    tmux kill-server 2>/dev/null
  fi
  # Sweep the whole scratch tree: fixture helpers (make_bare_repo, make_worktree)
  # are called via $(...) so their FIXTURE_DIRS appends happen in a subshell and
  # never reach us. Guarded so an unset or unexpected $SCRATCH can never delete
  # outside the scratchpad.
  if [[ -n "$SCRATCH" && "$SCRATCH" == */scratchpad/dotfiles-tests ]]; then
    command rm -rf -- "$SCRATCH"/*(DN) 2>/dev/null
  fi
  # Still honor anything appended directly from the parent shell (not via $(...)).
  for d in "${FIXTURE_DIRS[@]}"; do
    [[ -n "$d" ]] && command rm -rf -- "$d" 2>/dev/null
  done
  FIXTURE_SESSIONS=(); FIXTURE_DIRS=()
}

test_summary() {
  print -r -- ""
  print -r -- "  $((TESTS_RUN-TESTS_FAILED))/$TESTS_RUN passed"
  return $(( TESTS_FAILED > 0 ? 1 : 0 ))
}

mkdir -p "$SCRATCH"
trap cleanup_fixtures EXIT INT TERM
