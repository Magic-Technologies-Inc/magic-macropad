#!/bin/sh
# K1 action: open a terminal already running Claude Code in the K1 repo.

osascript <<'EOF'
tell application "Terminal"
    activate
    do script "cd ~/Developer/Magic/K1 && claude"
end tell
EOF
