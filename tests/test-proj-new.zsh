#!/bin/zsh
source "${0:A:h}/_harness.zsh"

# proj-new is a 6-step interactive wizard driven by fzf pickers, so an
# end-to-end run is not covered here. What IS covered: the worktree-discovery
# logic it now depends on, and static guards for the three defects fixed —
# a fabricated worktree path, a swallowed layout failure, and reimplemented
# session naming.

fn="$HOME/.dotfiles/.functions/proj-new"

assert_ok "proj-new parses" -- zsh -n "$fn"

# ── static guards ─────────────────────────────────────────────────────────────
# It must no longer build the path from the Step-3 answer: gwt-init always
# creates `main` and gwt-clone uses the repo's real default branch, so that
# answer is discarded and the path was frequently wrong.
assert_fail "no longer fabricates worktree_path from \$branch" -- \
  grep -qE 'worktree_path="\$dest/\$branch"' "$fn"

assert_ok "discovers the worktree from git instead" -- \
  grep -q 'worktree list --porcelain' "$fn"

# The layout failure must propagate — this is what let "✓ Done" print after a
# failed launch.
assert_ok "layout launch failure is propagated" -- \
  grep -qE 'if ! tmux-layout' "$fn"

# Session naming delegates rather than reimplementing the sanitize, which got
# slashed branch names wrong.
assert_ok "delegates naming to tmux-session-name" -- \
  grep -q 'session_name=$(tmux-session-name' "$fn"
assert_fail "no hand-rolled tr sanitize remains" -- \
  grep -qE "tr ' \.:/" "$fn"

# Exact-match tmux targets, consistent with the rest of the gwt family.
assert_fail "no bare -t targets" -- \
  grep -qE 'tmux (has-session|switch-client|attach-session|kill-session) -t [^=]' "$fn"

# ── the discovery logic, against real repo layouts ────────────────────────────
# Extract exactly the loop proj-new uses and run it over fixtures, so the
# behaviour is verified rather than just the presence of a grep-able string.
_discover() {  # _discover <bare-repo> → "<path>\t<branch>"
  local worktree_path="" actual_branch="" _p _b line
  while IFS= read -r line; do
    case "$line" in
      worktree\ *) _p="${line#worktree }" ;;
      bare)        _p="" ;;
      branch\ *)   _b="${${line#branch }#refs/heads/}"
                   [[ -n "$_p" && -z "$worktree_path" ]] && {
                     worktree_path="$_p"; actual_branch="$_b"
                   } ;;
    esac
  done < <(git -C "$1" worktree list --porcelain 2>/dev/null)
  print -r -- "${worktree_path}"$'\t'"${actual_branch}"
}

# A bare repo whose only worktree is `main` — the gwt-init shape.
bare=$(make_bare_repo pn-repo)
wt=$(make_worktree "$bare" main)
res=$(_discover "$bare")
assert_eq "$wt"   "${res%%$'\t'*}" "discovers the worktree path, not the bare repo"
assert_eq "main"  "${res##*$'\t'}" "discovers the actual branch"

# A repo whose default branch is NOT main — the case that broke the wizard when
# the user accepted the hardcoded 'main' default at Step 3.
bare2=$(make_bare_repo pn-trunk)
wt2=$(make_worktree "$bare2" trunk)
res=$(_discover "$bare2")
assert_eq "trunk" "${res##*$'\t'}" "discovers a non-main default branch"
assert_fail "would NOT have found \$dest/main (the old assumption)" -- \
  test -d "$bare2/main"

# A repo with no worktrees at all must yield nothing, so proj-new can abort
# rather than proceed against a path that does not exist.
bare3=$(make_bare_repo pn-empty)
res=$(_discover "$bare3")
assert_eq "" "${res%%$'\t'*}" "no worktrees → empty path, so the caller aborts"

cleanup_fixtures
test_summary
