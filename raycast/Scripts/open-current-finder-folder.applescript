#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open Current Finder Folder
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 📂

# Documentation:
# @raycast.description Opens the current open finder folder in Alacritty
# @raycast.author Mikhail

# Set alias to 'of'

on run
  set pathsToOpen to {}

  tell application "Finder"
    if exists (front window) then
      set end of pathsToOpen to POSIX path of (target of front window as alias)
    else
      -- Fallback to Desktop
      set end of pathsToOpen to POSIX path of (desktop as alias)
    end if
  end tell

  set openedCount to 0
  repeat with p in pathsToOpen
    set dirPath to contents of p
    set shellCommand to "eza -la --no-user --header; exec zsh"
    try
      -- Launch Alacritty using bundle ID, running ls -a first
      do shell script "/usr/bin/open -b org.alacritty --new --args --working-directory " & quoted form of dirPath & " -e zsh -c " & quoted form of shellCommand
      set openedCount to openedCount + 1
    on error e
      -- Fallback to explicit app path
      try
        do shell script "/usr/bin/open -na /Applications/Alacritty.app --args --working-directory " & quoted form of dirPath & " -e zsh -c " & quoted form of shellCommand
        set openedCount to openedCount + 1
      on error ee
        return "❌ Failed: " & ee
      end try
    end try
  end repeat

  return "Opened in Alacritty: " & openedCount & " item(s)"
end run
