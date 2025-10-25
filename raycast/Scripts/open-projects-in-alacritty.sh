#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open Projects in Alacritty
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 💻

# Documentation:
# @raycast.description Opens Projects in Alacritty
# @raycast.author Mikhail

# Set alias to 'op'

Alacritty --working-directory ~/Desktop/Projects -e zsh -c "eza -la --no-user --header; exec zsh"

