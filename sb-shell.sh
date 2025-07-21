#!/bin/sh

# Description: This script sources all the .sh files in the specified directory.
# Usage: Add this to your shell's config file: source "$HOME/.sb-shell/sb-shell.sh"
# Parameters: None

# Define the directory where the scripts are located
scripts_dir="$HOME/.sb-shell/scripts"

# Set environment variable to indicate we're loading sb-shell
export SB_SHELL_LOADING=1

# Check if the scripts directory exists
if [ ! -d "$scripts_dir" ]; then
  echo "Warning: sb-shell scripts directory not found at $scripts_dir" >&2
  return 1 2>/dev/null || exit 1
fi

# Check if any .sh files exist in the directory or subdirectories
script_count=0
# Use find to avoid glob expansion issues
if command -v find >/dev/null 2>&1; then
  script_count=$(find "$scripts_dir" -name "*.sh" -type f 2>/dev/null | wc -l)
else
  # Fallback: check patterns individually
  for pattern in "$scripts_dir"/*.sh "$scripts_dir"/*/*.sh; do
    # Check if the glob actually matched files (not just the pattern itself)
    [ -f "$pattern" ] && script_count=$((script_count + 1)) && break
  done
fi

if [ $script_count -eq 0 ]; then
  echo "Warning: No .sh files found in $scripts_dir" >&2
  return 1 2>/dev/null || exit 1
fi

# Loop through all the .sh files in the scripts directory and subdirectories
if command -v find >/dev/null 2>&1; then
  # Use find for more reliable file discovery
  # Create a temporary file to avoid subshell issues
  temp_file=$(mktemp 2>/dev/null) || temp_file="/tmp/sb-shell-$$"
  find "$scripts_dir" -name "*.sh" -type f 2>/dev/null > "$temp_file"
  while IFS= read -r script; do
    if [ -r "$script" ]; then
      # Check if script has a sb-shell guard or is a function-only script
      if grep -q "# sb-shell: auto-run" "$script" 2>/dev/null; then
        echo "Auto-running: $(basename "$script")"
        . "$script"
      else
        . "$script"
      fi
    else
      echo "Warning: Cannot read script file: $script" >&2
    fi
  done < "$temp_file"
  rm -f "$temp_file" 2>/dev/null
else
  # Fallback to glob patterns
  for script in "$scripts_dir"/*.sh "$scripts_dir"/*/*.sh; do
    # Check if the file exists and is readable
    if [ -r "$script" ]; then
      # Check if script has a sb-shell guard or is a function-only script
      if grep -q "# sb-shell: auto-run" "$script" 2>/dev/null; then
        echo "Auto-running: $(basename "$script")"
        . "$script"
      else
        . "$script"
      fi
    elif [ -e "$script" ]; then
      # Only warn if it's actually a file (not the glob pattern)
      echo "Warning: Cannot read script file: $script" >&2
    fi
  done
fi

# Clean up environment variable
unset SB_SHELL_LOADING
