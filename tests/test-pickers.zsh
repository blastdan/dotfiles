#!/bin/zsh
source "${0:A:h}/_harness.zsh"

# --- no function may use `exit` — these are autoloaded, so exit kills the shell
for f in tmux-sessionizer tmux-session-killer gwt gwt-add tpane tmux-layout tmux-session-name tmux-cheatsheet; do
  # NOTE: do not name this variable `path` — zsh ties the scalar `path` to the
  # `$PATH` array, and clobbering it here breaks command lookup for the rest
  # of the script.
  fn_path="$HOME/.dotfiles/.functions/$f"
  [[ -f "$fn_path" ]] || continue
  # Exclude comment lines and quoted string-literal data lines (e.g.
  # tmux-cheatsheet's raw_entries array), where "exit" is prose, not a
  # shell exit statement.
  hits=$(grep -nE '(^|[;&|[:space:]])exit([[:space:]]|$)' "$fn_path" | grep -v '^\s*#' | grep -v '^[0-9]*:\s*"' || true)
  assert_eq "" "$hits" "$f uses return, never exit"
done

# --- the calling shell must survive a cancelled picker ----------------------
out=$(zsh -c "
  fpath=($HOME/.dotfiles/.functions \$fpath)
  autoload -Uz tmux-sessionizer
  tmux-sessionizer '' >/dev/null 2>&1
  print SHELL_SURVIVED
")
assert_eq "SHELL_SURVIVED" "$out" "cancelling tmux-sessionizer does not kill the shell"

# --- dead code removed ------------------------------------------------------
assert_fail "gwt no longer defines the unused path_for_branch map" -- \
  grep -q 'path_for_branch' "$HOME/.dotfiles/.functions/gwt"

# --- session markers present ------------------------------------------------
assert_ok "gwt renders a session marker" -- \
  grep -qE '●|○' "$HOME/.dotfiles/.functions/gwt"
assert_ok "tmux-sessionizer renders a session marker" -- \
  grep -qE '●|○' "$HOME/.dotfiles/.functions/tmux-sessionizer"

# --- naming is delegated, not reimplemented ---------------------------------
assert_ok "gwt delegates to tmux-session-name" -- \
  grep -q 'tmux-session-name' "$HOME/.dotfiles/.functions/gwt"
assert_ok "tmux-sessionizer delegates to tmux-session-name" -- \
  grep -q 'tmux-session-name' "$HOME/.dotfiles/.functions/tmux-sessionizer"

# --- the $HOME-wide sweep is gone -------------------------------------------
assert_fail "tmux-sessionizer no longer sweeps all of \$HOME" -- \
  grep -qE 'find "\$HOME/source" "\$HOME"' "$HOME/.dotfiles/.functions/tmux-sessionizer"

cleanup_fixtures
test_summary
