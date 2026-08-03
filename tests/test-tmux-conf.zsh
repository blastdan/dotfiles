#!/bin/zsh
source "${0:A:h}/_harness.zsh"

conf="$HOME/.config/tmux/tmux.conf"

# No key may be bound twice within the same key table — this class of bug has occurred
# twice. Table-aware: groups by (table, key) so `v` can legitimately exist in both
# `prefix` and `copy-mode-vi` without a false positive, but two binds of the same key
# in the SAME table (e.g. two `prefix K`, or two `copy-mode-vi v`) are caught.
dupes=$(perl -ne '
  if (/^bind(?:-key)?\s+(-n\s+|-T\s+(\S+)\s+)?(\S+)/) {
    my ($flag, $table, $key) = ($1, $2, $3);
    if (defined $flag && $flag =~ /^-n/) { $table = "root"; }
    elsif (!defined $table) { $table = "prefix"; }
    print "$table $key\n";
  }
' "$conf" | sort | uniq -d)
assert_eq "" "$dupes" "no duplicate bind targets within any key table in tmux.conf"

# Layout binds must route through tmux-layout, never bare tmuxinator.
assert_fail "no bare 'tmuxinator start' bind remains" -- \
  grep -qE '^bind.*tmuxinator start [a-z]+\s*"?$' "$conf"
assert_ok "agent bind uses tmux-layout"  -- grep -qE '^bind +A .*tmux-layout agent' "$conf"
assert_ok "review bind uses tmux-layout" -- grep -qE '^bind +G .*tmux-layout review' "$conf"
assert_ok "watch bind uses tmux-layout"  -- grep -qE '^bind +W .*tmux-layout watch' "$conf"

# Layout binds must come AFTER the tpm run line, or plugins overwrite them.
tpm_line=$(grep -n "plugins/tpm/tpm" "$conf" | tail -1 | cut -d: -f1)
for key in A G W; do
  bind_line=$(grep -nE "^bind +$key " "$conf" | tail -1 | cut -d: -f1)
  if (( bind_line > tpm_line )); then
    _pass "prefix+$key bound after tpm (line $bind_line > $tpm_line)"
  else
    _fail "prefix+$key bound after tpm" "bind at $bind_line, tpm at $tpm_line"
  fi
done

# Live server checks, after sourcing.
if tmux has-session 2>/dev/null || [[ -n "$TMUX" ]]; then
  tmux source-file "$conf" 2>/dev/null
  keys=$(tmux list-keys -T prefix 2>/dev/null)
  assert_contains "$(print -r -- "$keys" | grep -E '^bind-key +-T prefix +K ')" \
    "resize-pane" "live: prefix+K is resize-pane again"
  assert_contains "$(print -r -- "$keys" | grep -E '^bind-key +-T prefix +Q ')" \
    "tmux-session-killer" "live: prefix+Q is the session killer"
  assert_contains "$(print -r -- "$keys" | grep -E '^bind-key +-T prefix +W ')" \
    "tmux-layout watch" "live: prefix+W is the watch layout"
  assert_contains "$(print -r -- "$keys" | grep -E '^bind-key +-T prefix +M ')" \
    "notify" "live: prefix+M still belongs to tmux-notify"
fi

# The cheatsheet must not advertise removed things. Match the multi LAYOUT
# specifically — "multi-select" appears in legitimate unrelated entries
# (the session killer, and `gadd`) and must survive.
cheat="$HOME/.functions/tmux-cheatsheet"
assert_fail "cheatsheet no longer advertises the multi layout" -- \
  grep -qiE 'Multi layout|layout multi' "$cheat"
assert_fail "cheatsheet no longer says opencode in a layout row" -- \
  grep -qiE '(Agent|Review) layout.*opencode' "$cheat"
assert_ok "cheatsheet documents prefix+Q for the killer" -- \
  grep -qE 'Ctrl-a Q' "$cheat"
assert_ok "cheatsheet documents prefix+W for watch" -- \
  grep -qE 'Ctrl-a W' "$cheat"

# Every `display-popup -E` / `run-shell` target that invokes a file under
# .functions must (a) be executable and (b) run standalone under a stripped
# environment (no .zshrc, no PATH additions, TMUX carried through) without
# "command not found" on stderr. This is the bug class Critical 2 hit twice:
# a script-mode invocation depending on a helper function that is only
# autoloaded in an interactive shell. Targets are parsed out of tmux.conf,
# not hardcoded, so a future bind is covered automatically.
#
# Note: only single-line binds are parsed (every current .functions target
# is single-line); a target split across a line continuation would not be
# picked up here.
targets=()
while IFS= read -r line; do
  quoted=$(print -r -- "$line" | grep -oE '"[^"]*"' | head -1)
  quoted="${quoted#\"}"; quoted="${quoted%\"}"
  first_word="${quoted%% *}"
  case "$first_word" in
    '$HOME/.functions/'*)
      targets+=("${first_word/\$HOME/$HOME}")
      ;;
  esac
done < <(grep -nE 'display-popup -E|run-shell' "$conf")

targets=(${(u)targets[@]})
[[ ${#targets[@]} -eq 0 ]] && _fail "found at least one .functions target bound in tmux.conf" "none parsed"

for target in "${targets[@]}"; do
  assert_ok "$target:t is executable" -- test -x "$target"

  stderr_out=$(timeout 5 env -i HOME="$HOME" PATH="$PATH" TMUX="$TMUX" \
    zsh -c "$target" </dev/null 2>&1 >/dev/null)
  if print -r -- "$stderr_out" | grep -qi 'command not found'; then
    _fail "$target:t runs standalone with no 'command not found'" "stderr: $stderr_out"
  else
    _pass "$target:t runs standalone with no 'command not found'"
  fi
done

test_summary
