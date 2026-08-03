#!/bin/zsh
# test-function-conventions.zsh: every .functions/<name> file's first non-shebang
# comment must be a real "# <name>: <description>" line, not a decorative separator.
source "${0:A:h}/_harness.zsh"

FUNCTIONS_DIR="$HOME/.dotfiles/.functions"

for f in "$FUNCTIONS_DIR"/*(.N); do
  name="${f:t}"
  line1=$(sed -n '1p' "$f")
  if [[ "$line1" == '#!'* ]]; then
    candidate=$(sed -n '2p' "$f")
  else
    candidate="$line1"
  fi

  if [[ "$candidate" == "# ${name}: "* ]]; then
    _pass "$name: line has a proper '# $name: <description>' comment"
  else
    _fail "$name: line has a proper '# $name: <description>' comment" "got: '$candidate'"
  fi
done

test_summary
