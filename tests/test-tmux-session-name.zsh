#!/bin/zsh
source "${0:A:h}/_harness.zsh"

# 1. Plain non-git directory → sanitised basename
plain="$SCRATCH/my.plain proj"
mkdir -p "$plain"; FIXTURE_DIRS+=("$plain")
assert_eq "my_plain_proj" "$(tmux-session-name "$plain")" "plain dir → sanitised basename"

# 2. Bare repo directory itself → repo name only
bare=$(make_bare_repo tsn-repo)
assert_eq "tsn-repo" "$(tmux-session-name "$bare")" "bare repo dir → repo name"

# 3. Worktree of a bare repo → repo_branch
wt=$(make_worktree "$bare" featx)
assert_eq "tsn-repo_featx" "$(tmux-session-name "$wt")" "worktree → repo_branch"

# 4. Slashed branch name (nested worktree dir) → still repo_branch, sanitised.
#    This is the case path arithmetic gets wrong.
wt2=$(make_worktree "$bare" feat/login)
assert_eq "tsn-repo_feat_login" "$(tmux-session-name "$wt2")" "slashed branch → repo_feat_login"

# 5. Regular (non-bare) clone → repo_branch
reg="$SCRATCH/tsn-regular"
git init -q -b main "$reg"; FIXTURE_DIRS+=("$reg")
git -C "$reg" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
assert_eq "tsn-regular_main" "$(tmux-session-name "$reg")" "regular clone → repo_branch"

# 6. Missing directory → non-zero exit
assert_fail "missing dir exits non-zero" -- tmux-session-name "$SCRATCH/does-not-exist"

# 7. No argument → non-zero exit
assert_fail "no argument exits non-zero" -- tmux-session-name

cleanup_fixtures
test_summary
