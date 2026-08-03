#!/bin/zsh
source "${0:A:h}/_harness.zsh"

if [[ -z "$TMUX" ]] && ! tmux has-session 2>/dev/null; then
  print -r -- "  SKIP — no tmux server available"
  exit 0
fi

bare=$(make_bare_repo tl-repo)
wt_a=$(make_worktree "$bare" alpha)
wt_b=$(make_worktree "$bare" beta)

# Guard rails first.
assert_fail "unknown layout rejected"   -- tmux-layout no-such-layout "$wt_a"
assert_fail "missing dir rejected"      -- tmux-layout agent "$SCRATCH/nope"
assert_fail "no args rejected"          -- tmux-layout

# Launch the agent layout for worktree alpha.
track_session "tl-repo_alpha"; track_session "tl-repo_beta"
tmux-layout agent "$wt_a" >/dev/null 2>&1
sleep 2
assert_ok "session tl-repo_alpha created" -- tmux has-session -t=tl-repo_alpha
assert_eq "$wt_a" "$(tmux display-message -p -t=tl-repo_alpha: '#{session_path}')" \
  "alpha session rooted at alpha worktree"

panes=$(tmux list-panes -t=tl-repo_alpha -F '#{pane_current_command}' | tr '\n' ' ')
assert_contains "$panes" "nvim"   "agent layout runs nvim"
assert_contains "$panes" "claude" "agent layout runs claude"

# THE REGRESSION TEST: a second worktree must get its own session, not alpha's.
tmux-layout agent "$wt_b" >/dev/null 2>&1
sleep 2
assert_ok "session tl-repo_beta created" -- tmux has-session -t=tl-repo_beta
assert_eq "$wt_b" "$(tmux display-message -p -t=tl-repo_beta: '#{session_path}')" \
  "beta session rooted at beta worktree (no collision)"
assert_eq "$wt_a" "$(tmux display-message -p -t=tl-repo_alpha: '#{session_path}')" \
  "alpha session still rooted at alpha"
assert_fail "no stray session named 'agent'" -- tmux has-session -t=agent

# Re-invoking for an existing session must reuse it, not error or duplicate.
before=$(tmux list-sessions -F '#{session_name}' | grep -c '^tl-repo_alpha$')
tmux-layout agent "$wt_a" >/dev/null 2>&1
after=$(tmux list-sessions -F '#{session_name}' | grep -c '^tl-repo_alpha$')
assert_eq "$before" "$after" "re-invoke reuses existing session"

# Script-mode invocation (what tmux run-shell does in Task 5). The harness
# autoloads every function, which would mask a failure here — so run it in a
# stripped environment with no autoload and no .zshrc.
wt_c=$(make_worktree "$bare" gamma)
track_session "tl-repo_gamma"
env -i HOME="$HOME" PATH="$PATH" TMUX="$TMUX" \
  zsh -c "$HOME/.functions/tmux-layout agent '$wt_c'" >/dev/null 2>&1
sleep 2
assert_ok "script-mode invocation creates the session" -- tmux has-session -t=tl-repo_gamma

cleanup_fixtures
test_summary
