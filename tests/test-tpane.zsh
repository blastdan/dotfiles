#!/bin/zsh
source "${0:A:h}/_harness.zsh"

if ! tmux has-session 2>/dev/null && [[ -z "$TMUX" ]]; then
  print -r -- "  SKIP — no tmux server available"
  exit 0
fi

sess="tp-test-$$"
track_session "$sess"
tmux new-session -ds "$sess" -c "$SCRATCH"
sleep 1
target=$(tmux list-panes -t="$sess" -F '#{pane_id}' | head -1)

# --- list --------------------------------------------------------------------
out=$(tpane list)
assert_contains "$out" "$target" "list includes the test pane id"
assert_contains "$out" "$sess"   "list includes the session name"

# --- write then read round-trip ---------------------------------------------
tpane write "$target" 'echo tpane_roundtrip_marker'
sleep 1
out=$(tpane read "$target")
assert_contains "$out" "tpane_roundtrip_marker" "write then read round-trips"

# --- --lines is honoured -----------------------------------------------------
tpane write "$target" 'for i in $(seq 1 40); do echo line_$i; done'
sleep 2
out=$(tpane read "$target" --lines 5)
assert_eq "5" "$(print -r -- "$out" | wc -l | tr -d ' ')" "--lines 5 returns 5 lines"

# --- --no-enter leaves the command unexecuted -------------------------------
tpane write "$target" --no-enter 'unexecuted_marker_text'
sleep 1
out=$(tpane read "$target")
assert_contains "$out" "unexecuted_marker_text" "--no-enter text appears on the prompt line"

# --- key sending -------------------------------------------------------------
assert_ok "key C-c accepted" -- tpane key "$target" C-c

# --- safety: refuse to write to our own pane --------------------------------
if [[ -n "$TMUX_PANE" ]]; then
  assert_fail "refuses to write to its own pane" -- tpane write "$TMUX_PANE" 'loop'
  assert_fail "refuses to send keys to its own pane" -- tpane key "$TMUX_PANE" C-c
fi

# --- errors ------------------------------------------------------------------
assert_fail "unknown subcommand rejected"   -- tpane frobnicate
assert_fail "no subcommand rejected"        -- tpane
assert_fail "nonexistent target rejected"   -- tpane read '%99999'
assert_fail "write with no text rejected"   -- tpane write "$target"

cleanup_fixtures
test_summary
