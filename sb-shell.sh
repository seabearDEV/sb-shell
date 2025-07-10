#!/bin/bash

# Description: This script sources all the .sh files in the specified directory.
# Usage: Add this to your .bashrc file: source "$HOME/.sb-shell/sb-shell.sh"
# Parameters: None

# Define the directory where the scripts are located
scripts_dir="$HOME/.sb-shell/scripts"

# Check if the scripts directory exists
if [[ ! -d "$scripts_dir" ]]; then
  echo "Warning: sb-shell scripts directory not found at $scripts_dir" >&2
  return 1
fi

# Use shell globbing with nullglob to handle no matches gracefully
shopt -s nullglob
script_files=("$scripts_dir"/*.sh)
shopt -u nullglob

# Check if any scripts were found
if [[ ${#script_files[@]} -eq 0 ]]; then
  echo "Warning: No .sh files found in $scripts_dir" >&2
  return 1
fi

# Loop through all the .sh files in the scripts directory
for script in "${script_files[@]}"; do
  # Check if the file is readable (more specific than just -f)
  if [[ -r "$script" ]]; then
    # Source the script file
    source "$script"
  else
    echo "Warning: Cannot read script file: $script" >&2
  fi
done
