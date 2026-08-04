#!/bin/zsh
# run-all.zsh: run every dotfiles test file, report aggregate result
#
# A skipped file is NOT a pass. Several test files self-skip when no tmux server
# is reachable; that once hid ~34 assertions while this runner still printed
# "all test files passed". Skips are now surfaced and make the run non-zero.
cd "${0:A:h}"
total_failed=0
total_skipped=0
skipped_files=()
for f in test-*.zsh; do
  print -r -- ""
  print -r -- "── $f ──"
  out=$(zsh "$f" 2>&1); rc=$?
  print -r -- "$out"
  (( rc != 0 )) && total_failed=$((total_failed+1))
  if print -r -- "$out" | grep -qi 'SKIP'; then
    total_skipped=$((total_skipped+1))
    skipped_files+=("$f")
  fi
done
print -r -- ""
if (( total_skipped > 0 )); then
  print -r -- "SKIPPED: ${total_skipped} file(s) — ${skipped_files[*]}"
fi
if (( total_failed > 0 || total_skipped > 0 )); then
  print -r -- "RESULT: ${total_failed} failed, ${total_skipped} skipped"
  exit 1
fi
print -r -- "RESULT: all test files passed"
