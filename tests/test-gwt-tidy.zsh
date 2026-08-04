#!/bin/zsh
source "${0:A:h}/_harness.zsh"

# gwt-tidy scans $HOME/source/repos, which we must not touch. Point HOME at the
# scratch tree so the whole run is confined to fixtures.
fake_home="$SCRATCH/home"
repos="$fake_home/source/repos/testorg"
mkdir -p "$repos"

repo="$repos/tidy-repo"
seed="$SCRATCH/tidy-seed"
mkdir -p "$seed"
git -C "$seed" init -q -b main
git -C "$seed" -c user.email=t@t -c user.name=t commit -q --allow-empty -m base
git clone -q --bare "$seed" "$repo"
git -C "$repo" symbolic-ref HEAD refs/heads/main
base=$(git -C "$repo" rev-parse main)
git -C "$repo" update-ref refs/remotes/origin/main "$base"

_wt() {
  git -C "$repo" worktree add -q -b "$1" "$repo/$1" main 2>/dev/null
  git -C "$repo" update-ref "refs/remotes/origin/$1" "$base"
}

_wt gone-a          # removable
_wt gone-b          # removable
_wt keep-dirty      # removable except for an uncommitted edit
print -r -- "x" > "$repo/keep-dirty/uncommitted.txt"
_wt keep-unpushed   # has a commit on no remote
git -C "$repo/keep-unpushed" -c user.email=t@t -c user.name=t commit -q --allow-empty -m local

# Run gwt-tidy with HOME redirected at the fixture tree.
tidy() {
  HOME="$fake_home" zsh -c "
    fpath=($HOME/.dotfiles/.functions \$fpath)
    autoload -Uz gwt-tidy gwt-classify tmux-session-name
    gwt-tidy $*
  " 2>&1
}

# ── --dry-run must change nothing ─────────────────────────────────────────────
before=$(git -C "$repo" worktree list | sort)
out=$(tidy --dry-run)
after=$(git -C "$repo" worktree list | sort)
assert_eq "$before" "$after" "--dry-run does not mutate the repo"
assert_contains "$out" "gone-a"   "--dry-run lists a removable worktree"
assert_contains "$out" "gone-b"   "--dry-run lists both removable worktrees"
assert_contains "$out" "2 of 4"   "--dry-run counts removable vs total"
assert_fail "--dry-run left gone-a in place is NOT a removal" -- \
  test ! -d "$repo/gone-a"

# ── unknown option rejected ───────────────────────────────────────────────────
assert_fail "unknown option rejected" -- \
  env HOME="$fake_home" zsh -c "fpath=($HOME/.dotfiles/.functions \$fpath); autoload -Uz gwt-tidy gwt-classify tmux-session-name; gwt-tidy --bogus"

# ── --yes removes ONLY the removable ones ─────────────────────────────────────
out=$(tidy --yes)
assert_ok   "gone-a directory removed"       -- test ! -d "$repo/gone-a"
assert_ok   "gone-b directory removed"       -- test ! -d "$repo/gone-b"
assert_ok   "dirty worktree preserved"       -- test -d "$repo/keep-dirty"
assert_ok   "unpushed worktree preserved"    -- test -d "$repo/keep-unpushed"

# THE safety property: branches survive. Every removal must be reversible.
assert_contains "$(git -C "$repo" branch --list gone-a)" "gone-a" \
  "branch gone-a still exists after its worktree was removed"
assert_contains "$(git -C "$repo" branch --list gone-b)" "gone-b" \
  "branch gone-b still exists after its worktree was removed"

# The uncommitted edit must be untouched.
assert_ok "dirty worktree's uncommitted file intact" -- \
  test -f "$repo/keep-dirty/uncommitted.txt"

# ── a second run finds nothing left to do ─────────────────────────────────────
out=$(tidy --dry-run)
assert_contains "$out" "0 of 2" "after tidying, nothing remains removable"

cleanup_fixtures
test_summary
