#!/bin/sh
# Magic Macropad action: open a terminal already running Claude Code in a
# project folder. Set PROJECT to your repo.

PROJECT="$HOME/Developer/your-project"

osascript - "$PROJECT" <<'OSA'
on run argv
    tell application "Terminal"
        activate
        do script "cd " & quoted form of (item 1 of argv) & " && claude"
    end tell
end run
OSA
