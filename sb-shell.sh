#!/bin/sh

# Description: This script sources all the .sh files in the specified directory.
# Usage: Add this to your shell's config file: source "$HOME/.sb-shell/sb-shell.sh"
# Parameters: None

# Define the directory where the scripts are located
scripts_dir="$HOME/.sb-shell/scripts"

# Check if the scripts directory exists
if [ ! -d "$scripts_dir" ]; then
  echo "Warning: sb-shell scripts directory not found at $scripts_dir" >&2
  return 1 2>/dev/null || exit 1
fi

# Check if any .sh files exist in the directory
script_count=0
for script in "$scripts_dir"/*.sh; do
  # Check if the glob actually matched files (not just the pattern itself)
  if [ -f "$script" ]; then
    script_count=$((script_count + 1))
    break
  fi
done

if [ $script_count -eq 0 ]; then
  echo "Warning: No .sh files found in $scripts_dir" >&2
  return 1 2>/dev/null || exit 1
fi

# Loop through all the .sh files in the scripts directory
for script in "$scripts_dir"/*.sh; do
  # Check if the file exists and is readable
  if [ -r "$script" ]; then
    # Source the script file
    . "$script"
  else
    # Only warn if it's actually a file (not the glob pattern)
    if [ -e "$script" ]; then
      echo "Warning: Cannot read script file: $script" >&2
    fi
  fi
done
