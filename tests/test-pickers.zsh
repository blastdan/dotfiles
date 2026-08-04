#!/bin/zsh
source "${0:A:h}/_harness.zsh"

# --- no function may use `exit` — these are autoloaded, so exit kills the shell
# Widened leading-character class to also catch `(exit 0)` / `{exit 0;}` forms
# with no space after the bracket — no such case exists today, but the guard
# should not depend on that staying true.
for f in tmux-sessionizer tmux-session-killer gwt gwt-add tpane tmux-layout tmux-session-name tmux-cheatsheet; do
  # NOTE: do not name this variable `path` — zsh ties the scalar `path` to the
  # `$PATH` array, and clobbering it here breaks command lookup for the rest
  # of the script.
  fn_path="$HOME/.dotfiles/.functions/$f"
  [[ -f "$fn_path" ]] || continue
  # Exclude comment lines and quoted string-literal data lines (e.g.
  # tmux-cheatsheet's raw_entries array), where "exit" is prose, not a
  # shell exit statement.
  hits=$(grep -nE '(^|[;&|[:space:]({])exit([[:space:]]|$)' "$fn_path" | grep -v '^\s*#' | grep -v '^[0-9]*:\s*"' || true)
  assert_eq "" "$hits" "$f uses return, never exit"
done

# --- the calling shell must survive an empty selection -----------------------
# NOTE: this exercises the `[[ -z "$selected" ]] && return 0` guard directly
# (via the `[path]` argument branch, which skips fzf entirely) — it is a
# regression guard for the exact line where the original `exit 0` lived, not a
# simulation of an interactive fzf Esc-cancel.
out=$(zsh -c "
  fpath=($HOME/.dotfiles/.functions \$fpath)
  autoload -Uz tmux-sessionizer
  tmux-sessionizer '' >/dev/null 2>&1
  print SHELL_SURVIVED
")
assert_eq "SHELL_SURVIVED" "$out" "tmux-sessionizer: empty selection returns without killing the shell"

# --- gwt: the calling shell must survive an empty (cancelled) fzf selection --
# gwt has no [path] argument shortcut, so this drives the real fzf invocation
# but replaces the `fzf` binary on PATH with a no-op that prints nothing,
# reproducing exactly what an Esc-cancel produces (empty stdout, exit 0).
gwt_fixture_bare=$(make_bare_repo gwt-survival)
gwt_fixture_wt=$(make_worktree "$gwt_fixture_bare" main)
fake_fzf_dir="$SCRATCH/fake-fzf-bin"
mkdir -p "$fake_fzf_dir"
cat > "$fake_fzf_dir/fzf" <<'FAKEFZF'
#!/bin/zsh
cat >/dev/null   # drain stdin, print nothing — simulates Esc
FAKEFZF
chmod +x "$fake_fzf_dir/fzf"
out=$(zsh -c "
  fpath=($HOME/.dotfiles/.functions \$fpath)
  autoload -Uz gwt tmux-session-name
  PATH='$fake_fzf_dir:\$PATH'
  cd '$gwt_fixture_wt'
  gwt >/dev/null 2>&1
  print SHELL_SURVIVED
")
assert_eq "SHELL_SURVIVED" "$out" "gwt: empty selection returns without killing the shell"

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

# --- stale/prunable worktrees are excluded, silently, from both pickers -----
# `git worktree list --porcelain` keeps listing a worktree whose directory
# was deleted out from under it (reports it `prunable`), which previously
# made tmux-session-name fail loudly (stderr spray into the fzf popup) and,
# because its empty output could match the blank line `$live` produces with
# no sessions running, show a false ● on an unusable row.
real_home="$HOME"

# fake fzf: dump whatever candidate list it's fed to a file, select nothing.
fake_fzf_dir2="$SCRATCH/fake-fzf-bin2"
mkdir -p "$fake_fzf_dir2"
cat > "$fake_fzf_dir2/fzf" <<'FAKEFZF'
#!/bin/zsh
cat > "$FZF_CAPTURE_FILE"
FAKEFZF
chmod +x "$fake_fzf_dir2/fzf"

## gwt: prunable worktree alongside a normal, still-valid one
prune_bare=$(make_bare_repo prune-repo)
prune_wt=$(make_worktree "$prune_bare" gone)
make_worktree "$prune_bare" valid >/dev/null
command rm -rf "$prune_wt"   # dir gone, git metadata (and "prunable") remains

gwt_capture="$SCRATCH/gwt-candidates.txt"
gwt_stderr="$SCRATCH/gwt-stderr.txt"
: > "$gwt_capture"
FZF_CAPTURE_FILE="$gwt_capture" PATH="$fake_fzf_dir2:$PATH" \
  zsh -c "
    fpath=('$real_home/.dotfiles/.functions' \$fpath)
    autoload -Uz gwt tmux-session-name
    cd '$prune_bare'
    gwt >/dev/null 2>'$gwt_stderr'
  "
assert_fail "gwt: prunable worktree excluded from candidate list" -- \
  grep -q "gone" "$gwt_capture"
assert_eq "" "$(cat "$gwt_stderr")" "gwt: no stderr spray from the prunable worktree"

## tmux-sessionizer: prunable worktree under a fake $HOME/source/repos
sess_home="$SCRATCH/sessionizer-home"
sess_org="$sess_home/source/repos/testorg"
mkdir -p "$sess_org"
seed="$SCRATCH/.seed-ts-repo"
mkdir -p "$seed"
git -C "$seed" init -q -b main
git -C "$seed" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
git clone -q --bare "$seed" "$sess_org/ts-repo" 2>/dev/null
git -C "$sess_org/ts-repo" worktree add -q -b feature "$sess_org/ts-repo/feature" 2>/dev/null
command rm -rf "$sess_org/ts-repo/feature"   # dir gone, "prunable" remains

# A symlinked repo directory must still surface as a candidate: zsh's `/`
# glob qualifier is lstat-based and skips symlinks, unlike the `[[ -d ]]`
# check it replaced, so the org/repo scan must use `-/` (follow symlinks).
sym_target="$SCRATCH/.symtarget-repo"
mkdir -p "$sym_target"
git -C "$sym_target" init -q -b main
git -C "$sym_target" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
ln -s "$sym_target" "$sess_org/symrepo"

ts_capture="$SCRATCH/ts-candidates.txt"
ts_stderr="$SCRATCH/ts-stderr.txt"
: > "$ts_capture"
FZF_CAPTURE_FILE="$ts_capture" PATH="$fake_fzf_dir2:$PATH" \
  zsh -c "
    fpath=('$real_home/.dotfiles/.functions' \$fpath)
    autoload -Uz tmux-sessionizer tmux-session-name
    export HOME='$sess_home'
    tmux-sessionizer >/dev/null 2>'$ts_stderr'
  "
assert_fail "tmux-sessionizer: prunable worktree excluded from candidate list" -- \
  grep -q "feature" "$ts_capture"
assert_eq "" "$(cat "$ts_stderr")" "tmux-sessionizer: no stderr spray from the prunable worktree"
assert_ok "tmux-sessionizer: symlinked repo directory appears as a candidate" -- \
  grep -q "symrepo" "$ts_capture"

cleanup_fixtures
test_summary
