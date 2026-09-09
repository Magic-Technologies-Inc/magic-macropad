#!/bin/sh
# K1 action: ask Claude about whatever text is on the clipboard; the answer
# pops up as a dialog. Headless via the claude CLI — no windows moved.

CLAUDE="$HOME/.local/bin/claude"
Q=$(pbpaste)
[ -z "$Q" ] && exit 0

# Prompt goes via stdin: --allowedTools is variadic and would swallow a
# positional prompt argument.
A=$(printf 'Answer briefly (a few sentences, plain text): %s' "$Q" |
    "$CLAUDE" -p --allowedTools "WebSearch,WebFetch" 2>&1)
[ -z "$A" ] && A="(no answer — is the claude CLI logged in?)"

osascript - "$A" <<'EOF'
on run argv
    display dialog (item 1 of argv) buttons {"OK"} default button 1 with title "Claude" giving up after 120
end run
EOF
