#!/bin/zsh
source "${0:A:h}/_harness.zsh"

bare=$(make_bare_repo ga-repo)

# --- default: worktree only, NO session -------------------------------------
track_session "ga-repo_solo"
( cd "$bare" && gwt-add solo --new ) >/dev/null 2>&1
assert_ok  "default: worktree dir created" -- test -d "$bare/solo"
assert_fail "default: NO tmux session created" -- tmux has-session -t=ga-repo_solo

# --- --session: worktree + plain session ------------------------------------
track_session "ga-repo_withsess"
( cd "$bare" && gwt-add withsess --new --session ) >/dev/null 2>&1
sleep 1
assert_ok "--session: worktree created" -- test -d "$bare/withsess"
assert_ok "--session: session created"  -- tmux has-session -t=ga-repo_withsess
assert_eq "$bare/withsess" \
  "$(tmux display-message -p -t=ga-repo_withsess: '#{session_path}')" \
  "--session: rooted at the new worktree"

# --- --layout agent ----------------------------------------------------------
track_session "ga-repo_lay"
( cd "$bare" && gwt-add lay --new --layout agent ) >/dev/null 2>&1
sleep 2
assert_ok "--layout agent: session created" -- tmux has-session -t=ga-repo_lay
panes=$(tmux list-panes -t=ga-repo_lay -F '#{pane_current_command}' | tr '\n' ' ')
assert_contains "$panes" "claude" "--layout agent: claude pane running"

# --- --layout none is a synonym for --session --------------------------------
track_session "ga-repo_lnone"
( cd "$bare" && gwt-add lnone --new --layout none ) >/dev/null 2>&1
sleep 1
assert_ok "--layout none: session created" -- tmux has-session -t=ga-repo_lnone

# --- errors ------------------------------------------------------------------
assert_fail "existing worktree path rejected" -- \
  zsh -c "fpath=($HOME/.dotfiles/.functions \$fpath); autoload -Uz gwt-add; cd $bare && gwt-add solo --new"
assert_fail "unknown layout rejected" -- \
  zsh -c "fpath=($HOME/.dotfiles/.functions \$fpath); autoload -Uz gwt-add; cd $bare && gwt-add bogus --new --layout nope"
assert_fail "--layout with no value rejected" -- \
  zsh -c "fpath=($HOME/.dotfiles/.functions \$fpath); autoload -Uz gwt-add; cd $bare && gwt-add zzz --new --layout"
assert_fail "no branch argument rejected" -- \
  zsh -c "fpath=($HOME/.dotfiles/.functions \$fpath); autoload -Uz gwt-add; cd $bare && gwt-add"

cleanup_fixtures
test_summary
