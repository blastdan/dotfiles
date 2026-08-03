#!/bin/zsh
# _harness.zsh: assertion helpers and git/tmux fixtures for dotfiles tests

SCRATCH="/tmp/claude-1000/-home-daniel/725b72c6-4ee3-4143-bc95-1f6535996795/scratchpad/dotfiles-tests"
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

cleanup_fixtures() {
  local s d
  for s in "${FIXTURE_SESSIONS[@]}"; do tmux kill-session -t="$s" 2>/dev/null; done
  for d in "${FIXTURE_DIRS[@]}"; do rm -rf "$d" 2>/dev/null; done
  FIXTURE_SESSIONS=(); FIXTURE_DIRS=()
}

test_summary() {
  print -r -- ""
  print -r -- "  $((TESTS_RUN-TESTS_FAILED))/$TESTS_RUN passed"
  return $(( TESTS_FAILED > 0 ? 1 : 0 ))
}

mkdir -p "$SCRATCH"
trap cleanup_fixtures EXIT INT TERM
