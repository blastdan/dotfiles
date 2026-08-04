#!/bin/zsh
source "${0:A:h}/_harness.zsh"

# The cheatsheet (Ctrl-a ?) is hand-maintained, so it drifts silently. It had
# advertised the `multi` layout and `opencode` panes long after both were deleted,
# and `aws_profile` after that function was removed. This test is the mechanism it
# previously lacked: every function and every user-defined alias must appear, and
# nothing may reference something that no longer exists.

CS="$HOME/.dotfiles/.functions/tmux-cheatsheet"
assert_ok "cheatsheet parses" -- zsh -n "$CS"

# Key tokens actually documented. Entries legitimately pair several names in one
# key field ("gd / gds", "cp / mv / rm"), so split on "/" and take the first word
# of each part — "gwta <branch>" documents `gwta`.
# NOTE: literal tabs, via $'...'. GNU grep -E does not interpret \t, so writing
# '\t' here silently matched nothing and reported every alias as undocumented.
grep -oE $'^  "(bind|cmd)\t[^\t]+' "$CS" | sed $'s/^.*\t//' | tr '/' '\n' \
  | sed 's/^ *//; s/ *$//' | awk '{print $1}' | sort -u > "$SCRATCH/keys.txt"

# ── every function is reachable from the cheatsheet ───────────────────────────
# Either by its own name, or via an alias that points at it.
typeset -A alias_of
while IFS= read -r l; do
  n="${${l#alias }%%=*}"; v="${l#*=}"; v="${v//\'/}"
  alias_of[$n]="$v"
done < <(grep -h '^alias' "$HOME"/.dotfiles/.alias/*)

missing_fns=()
for f in "$HOME"/.dotfiles/.functions/*; do
  fn="${f:t}"
  grep -qF "$fn" "$CS" && continue
  found=""
  for n v in ${(kv)alias_of}; do
    [[ "$v" == "$fn"* ]] && grep -qxF "$n" "$SCRATCH/keys.txt" && { found=1; break }
  done
  [[ -z "$found" ]] && missing_fns+=("$fn")
done
assert_eq "" "${missing_fns[*]}" "every .functions/ entry is documented in the cheatsheet"

# ── every user-defined alias is documented ────────────────────────────────────
# fsh-alias comes from fast-syntax-highlighting and which-command is a zsh
# builtin alias; neither is ours to document.
typeset -a skip_aliases=(fsh-alias which-command run-help)
missing_aliases=()
for n in ${(k)alias_of}; do
  (( ${skip_aliases[(Ie)$n]} )) && continue
  grep -qxF "$n" "$SCRATCH/keys.txt" || missing_aliases+=("$n")
done
assert_eq "" "${missing_aliases[*]}" "every user-defined alias is documented in the cheatsheet"

# ── nothing stale: no reference to a deleted function ─────────────────────────
# These were all documented after being deleted, which is the failure this guards.
for gone in aws_profile agent-workspace review-workspace multi-agent; do
  assert_fail "cheatsheet does not reference deleted '$gone'" -- grep -qF "$gone" "$CS"
done
assert_fail "no reference to the deleted 'multi' layout" -- \
  grep -qiE 'Multi layout|layout multi' "$CS"

# ── every tmuxinator layout that IS referenced must exist ─────────────────────
for lay in $(grep -oE 'layout (agent|review|watch|multi|none)' "$CS" | awk '{print $2}' | sort -u); do
  [[ "$lay" == none ]] && continue
  assert_ok "referenced layout '$lay' exists" -- \
    test -f "$HOME/.dotfiles/.config/tmuxinator/${lay}.yml"
done

# ── keybinds: every prefix bind in tmux.conf is documented ────────────────────
# Fixed-string matching throughout: `?` and `\` are regex metacharacters and
# silently produced false "undocumented" results when matched as patterns.
missing_binds=()
for k in $(grep -oP '^bind(-key)? \K[^ ]+' "$HOME/.dotfiles/.config/tmux/tmux.conf" | grep -v '^-' | sort -u); do
  grep -qF "	Ctrl-a $k	" "$CS" && continue
  grep -qF "	$k	" "$CS" && continue
  # windows 1-9 are documented as a single range entry
  [[ "$k" == <-> ]] && grep -qF 'Ctrl-a 1-9' "$CS" && continue
  missing_binds+=("$k")
done
assert_eq "" "${missing_binds[*]}" "every prefix keybind is documented in the cheatsheet"

cleanup_fixtures
test_summary
