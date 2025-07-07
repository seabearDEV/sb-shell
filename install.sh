#!/bin/bash

# Description: This script installs sb-shell scripts to the user's home directory.
# Usage: Run the script and follow the prompts to install sb-shell scripts.
# Parameters: None

# Function to install sb-shell scripts
install_sb_shell() {
  local INSTALL_DIR="$HOME/.sb-shell"

  # Check if the directory exists, remove it if it does
  if [[ -d "$INSTALL_DIR" ]]; then
    echo "The directory already exists, deleting it..."
    rm -rf "$INSTALL_DIR"
  fi

  # Create the directory
  echo "Creating directory '$INSTALL_DIR'..."
  mkdir "$INSTALL_DIR"

  # Copy the scripts to the directory
  echo "Installing scripts to $INSTALL_DIR..."
  cp ./sb-shell.sh "$INSTALL_DIR"
  cp -r ./scripts* "$INSTALL_DIR"

  # Source the .bashrc file
  echo "Scripts installed successfully, sourcing the .bashrc file..."
  source "$HOME/.bashrc"

  echo "Sourcing complete, please be sure to add the following line to your .bashrc or .zshrc file:"
  echo 'source "$HOME/.sb-shell/sb-shell.sh"'
}

# Prompt the user for confirmation
echo "Install sb-shell scripts to '$HOME/.sb-shell'? (y/n)"
read response

# Check the user's response and install if confirmed
if [[ "$response" == "y" ]]; then
  install_sb_shell
else
  echo "Installation cancelled."
fi
