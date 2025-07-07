#!/bin/bash

# Description: This script sources all the .sh files in the specified directory.
# Usage: Add this to your .bashrc file: source "$HOME/.sb-shell/sb-shell.sh"
# Parameters: None

# Define the directory where the scripts are located
scripts_dir="$HOME/.sb-shell/scripts"

# Loop through all the .sh files in the scripts directory
for script in "$scripts_dir/"*.sh; do
  # Check if the file exists and is a regular file
  if [[ -f "$script" ]]; then
    # Source the script file
    source "$script"
  fi
done
