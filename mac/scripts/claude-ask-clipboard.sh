#!/bin/sh
# K1 action: ask Claude about whatever text is on the clipboard; the answer
# pops up as a dialog. Headless via the claude CLI — no windows moved.

CLAUDE="$HOME/.local/bin/claude"
Q=$(pbpaste)
[ -z "$Q" ] && exit 0

A=$("$CLAUDE" -p "Answer briefly (a few sentences, plain text): $Q" 2>&1)
[ -z "$A" ] && A="(no answer — is the claude CLI logged in?)"

osascript - "$A" <<'EOF'
on run argv
    display dialog (item 1 of argv) buttons {"OK"} default button 1 with title "Claude" giving up after 120
end run
EOF
