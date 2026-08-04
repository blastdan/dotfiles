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
# Use a marker whose *execution* produces a distinctive bare line that cannot
# appear from the typed-but-unexecuted echo alone: if Enter were pressed (a
# regression), the pane would show the typed "echo NOENTER_DID_RUN" line AND
# a separate bare "NOENTER_DID_RUN" output line from the echo actually
# running. If --no-enter behaves correctly, only the typed line appears.
tpane write "$target" --no-enter 'echo NOENTER_DID_RUN'
sleep 1
out=$(tpane read "$target")
assert_contains "$out" "echo NOENTER_DID_RUN" "--no-enter text appears on the prompt line"
bare_lines=$(print -r -- "$out" | grep -c '^NOENTER_DID_RUN$')
assert_eq "0" "$bare_lines" "--no-enter does not execute the command"

# --- key sending -------------------------------------------------------------
# (also clears the still-pending, unexecuted NOENTER_DID_RUN command line)
assert_ok "key C-c accepted" -- tpane key "$target" C-c

# --- safety: refuse to write to our own pane --------------------------------
# The harness unsets TMUX_PANE (so nothing under test can switch-client the
# user's real client), so point it at a pane on our own private server. This
# makes the guard assertions unconditional — previously they were skipped
# whenever the suite ran outside tmux, which is the normal case.
TMUX_PANE="$target" assert_fail "refuses to write to its own pane" -- \
  tpane write "$target" 'loop'
TMUX_PANE="$target" assert_fail "refuses to send keys to its own pane" -- \
  tpane key "$target" C-c
# And the guard must NOT fire for a different pane on the same server.
tmux split-window -t "$target" -d 2>/dev/null
other=$(tmux list-panes -t=tp-test-$$ -F '#{pane_id}' | grep -vF "$target" | head -1)
if [[ -n "$other" ]]; then
  TMUX_PANE="$target" assert_ok "still writes to a DIFFERENT pane" -- \
    tpane write "$other" 'echo ok'
fi

# --- errors ------------------------------------------------------------------
assert_fail "unknown subcommand rejected"   -- tpane frobnicate
assert_fail "no subcommand rejected"        -- tpane
assert_fail "nonexistent target rejected"   -- tpane read '%99999'
assert_fail "write with no text rejected"   -- tpane write "$target"

# --- --lines validation -------------------------------------------------------
assert_fail "--lines with non-numeric value rejected" -- tpane read "$target" --lines abc
assert_fail "--lines with no value rejected"          -- tpane read "$target" --lines

err=$(tpane read "$target" --lines abc 2>&1 >/dev/null)
assert_contains "$err" "tpane read:" "invalid --lines gives a tpane-level error message"
assert_eq "0" "$(print -r -- "$err" | grep -c 'tail:')" "invalid --lines does not leak a raw tail error"

cleanup_fixtures
test_summary
