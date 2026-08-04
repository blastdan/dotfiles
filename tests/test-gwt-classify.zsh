#!/bin/zsh
source "${0:A:h}/_harness.zsh"

# Build one bare repo whose worktrees sit deliberately in every state.
# Everything lives on the private tmux server / scratch dir per the harness.
repo="$SCRATCH/cls-repo"
seed="$SCRATCH/cls-seed"
mkdir -p "$seed"
git -C "$seed" init -q -b main
git -C "$seed" -c user.email=t@t -c user.name=t commit -q --allow-empty -m base
git clone -q --bare "$seed" "$repo"
git -C "$repo" symbolic-ref HEAD refs/heads/main

base=$(git -C "$repo" rev-parse main)
# A bare clone has no remote-tracking refs, so "is it pushed?" would count every
# commit as unpushed. Create the refs explicitly to model a pushed branch.
git -C "$repo" update-ref refs/remotes/origin/main "$base"

_wt() {  # _wt <branch> <dir-name>  → worktree at $repo/<dir-name> on <branch>
  git -C "$repo" worktree add -q -b "$1" "$repo/$2" main 2>/dev/null
  git -C "$repo" update-ref "refs/remotes/origin/$1" "$base"
}

# 1. removable — merged into main (same commit), clean, pushed
_wt wt-removable removable

# 2. dirty — merged + pushed, but with an uncommitted edit
_wt wt-dirty dirty
print -r -- "scratch" > "$repo/dirty/uncommitted.txt"

# 3. unpushed — has a commit that exists on no remote
_wt wt-unpushed unpushed
git -C "$repo/unpushed" -c user.email=t@t -c user.name=t \
  commit -q --allow-empty -m "local only"

# 4. default — the worktree holding the repo's default branch
git -C "$repo" worktree add -q "$repo/main-wt" main 2>/dev/null

# 5. detached — no branch at all
git -C "$repo" worktree add -q --detach "$repo/detached" "$base" 2>/dev/null

# 6. prunable — git record intact, directory deleted
_wt wt-prunable prunable
command rm -rf "$repo/prunable"

# 7. live — removable, but a tmux session for it exists
_wt wt-live live
live_name=$(tmux-session-name "$repo/live")
track_session "$live_name"
tmux new-session -ds "$live_name" -c "$repo/live" 2>/dev/null

# 8. directory name deliberately disagrees with the branch checked out in it
_wt wt-mismatch some-other-dirname

# ── helper: state for a given worktree directory ──────────────────────────────
state_of() {
  gwt-classify "$repo" 2>/dev/null | awk -F'\t' -v p="$1" '$1==p {print $3}'
}
branch_of() {
  gwt-classify "$repo" 2>/dev/null | awk -F'\t' -v p="$1" '$1==p {print $2}'
}

assert_eq "removable" "$(state_of "$repo/removable")" "merged+clean+pushed → removable"
assert_eq "dirty"     "$(state_of "$repo/dirty")"     "uncommitted changes → dirty"
assert_eq "unpushed"  "$(state_of "$repo/unpushed")"  "commit on no remote → unpushed"
assert_eq "default"   "$(state_of "$repo/main-wt")"   "default branch → default"
assert_eq "detached"  "$(state_of "$repo/detached")"  "detached HEAD → detached"
assert_eq "prunable"  "$(state_of "$repo/prunable")"  "deleted dir → prunable"
assert_eq "live"      "$(state_of "$repo/live")"      "live tmux session → live"

# Classified by BRANCH, never by directory name — 3 real worktrees in the user's
# repos have a directory that disagrees with the branch checked out in them.
assert_eq "wt-mismatch" "$(branch_of "$repo/some-other-dirname")" \
  "branch comes from git, not the directory name"
assert_eq "removable"   "$(state_of "$repo/some-other-dirname")" \
  "dir!=branch is still classified on its merits"

# The bare repo itself must never appear as a candidate.
assert_eq "" "$(state_of "$repo")" "bare repo itself is not listed"

# Precedence: dirty AND unpushed reports the more dangerous state.
_wt wt-both both
git -C "$repo/both" -c user.email=t@t -c user.name=t commit -q --allow-empty -m local
print -r -- "x" > "$repo/both/uncommitted.txt"
assert_eq "dirty" "$(state_of "$repo/both")" "dirty outranks unpushed"

# Clean and pushed but NOT merged is `unmerged`, distinct from `unpushed` — the
# work is safe on a remote, it just is not finished. Conflating the two would
# misreport why a worktree is being kept.
git -C "$repo" worktree add -q -b wt-unmerged "$repo/unmerged" main 2>/dev/null
git -C "$repo/unmerged" -c user.email=t@t -c user.name=t commit -q --allow-empty -m ahead
git -C "$repo" update-ref refs/remotes/origin/wt-unmerged "$(git -C "$repo" rev-parse wt-unmerged)"
assert_eq "unmerged" "$(state_of "$repo/unmerged")" "pushed but not merged → unmerged"

# Error handling
assert_fail "missing argument rejected"   -- gwt-classify
assert_fail "non-repo path rejected"      -- gwt-classify "$SCRATCH"

# Nothing in the classifier may mutate the repo.
before=$(git -C "$repo" worktree list | sort)
gwt-classify "$repo" >/dev/null 2>&1
after=$(git -C "$repo" worktree list | sort)
assert_eq "$before" "$after" "gwt-classify does not mutate the repo"

cleanup_fixtures
test_summary
