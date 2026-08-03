#!/bin/zsh
# run-all.zsh: run every dotfiles test file, report aggregate result
cd "${0:A:h}"
total_failed=0
for f in test-*.zsh; do
  print -r -- ""
  print -r -- "── $f ──"
  zsh "$f" || total_failed=$((total_failed+1))
done
print -r -- ""
if (( total_failed > 0 )); then
  print -r -- "RESULT: $total_failed test file(s) failed"
  exit 1
fi
print -r -- "RESULT: all test files passed"
