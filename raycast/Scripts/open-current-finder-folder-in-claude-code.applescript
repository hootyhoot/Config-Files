#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open Current Finder Folder in Claude Code
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🧠

# Documentation:
# @raycast.description Opens the current open finder folder in Claude Code inside Alacritty
# @raycast.author Mikhail

# Set alias to 'of'

on run
  tell application "Finder"
    if exists (front window) then
      set dirPath to POSIX path of (target of front window as alias)
    else
      -- Fallback to Desktop
      set dirPath to POSIX path of (desktop as alias)
    end if
  end tell

  set shellCommand to "/opt/homebrew/bin/claude -c || /opt/homebrew/bin/claude; exec zsh"

  -- Launch Claude Code inside Alacritty
  do shell script "/opt/homebrew/bin/alacritty --working-directory " & quoted form of dirPath & " -e zsh -c " & quoted form of shellCommand & " >/dev/null 2>&1 &"

  return "Opened in Claude Code: " & dirPath
end run
