#!/bin/sh
# K1 action: select a screen region -> new Claude chat with it pasted.
#
# screencapture -i lets you drag a region (Esc cancels, space toggles
# window mode); -c puts it on the clipboard. Then Cmd+N / Cmd+V in Claude.
#
# Needs (granted to MagicKeys.app, which runs this): Screen Recording for
# screencapture, Accessibility for the System Events keystrokes.

screencapture -ic || exit 0

osascript <<'EOF'
tell application "Claude" to activate
delay 0.5
tell application "System Events" to keystroke "n" using command down
delay 0.4
tell application "System Events" to keystroke "v" using command down
EOF
