#!/bin/bash

# Description: This script installs sb-shell scripts to the user's home directory.
# Usage: Run the script and follow the prompts to install sb-shell scripts.
# Parameters: None

# Function to install sb-shell scripts
install_sb_shell() {
  local INSTALL_DIR="$HOME/.sb-shell"

  # Check if the directory exists and warn the user
  if [[ -d "$INSTALL_DIR" ]]; then
    echo ""
    echo "WARNING: The directory '$INSTALL_DIR' already exists!"
    echo "Continuing will DELETE all existing sb-shell scripts and configurations."
    echo ""
    echo "Do you want to continue and replace the existing installation? (y/N)"
    read replace_response
    
    if [[ "$replace_response" != "y" && "$replace_response" != "Y" ]]; then
      echo "Installation cancelled. Existing installation preserved."
      return 1
    fi
    
    echo "Removing existing directory..."
    rm -rf "$INSTALL_DIR"
  fi

  # Create the directory
  echo "Creating directory '$INSTALL_DIR'..."
  mkdir "$INSTALL_DIR"

  # Copy the scripts to the directory
  echo "Installing scripts to $INSTALL_DIR..."
  cp ./sb-shell.sh "$INSTALL_DIR"
  cp -r ./scripts* "$INSTALL_DIR"

  # Installation complete message
  echo "Scripts installed successfully!"
  echo ""
  echo "To complete the installation, add the following line to your shell's configuration file:"
  echo '  source "$HOME/.sb-shell/sb-shell.sh"'
  echo ""
  echo "Common shell configuration files:"
  echo "  - Bash: ~/.bashrc or ~/.bash_profile"
  echo "  - Zsh: ~/.zshrc"
  echo "  - Fish: ~/.config/fish/config.fish (use 'source' command)"
  echo "  - Other shells: Add to your shell's initialization file"
}

# Prompt the user for confirmation
echo "Install sb-shell scripts to '$HOME/.sb-shell'? (Y/n)"
read response

# Check the user's response and install if confirmed
if [[ "$response" == "y" || "$response" == "Y" || -z "$response" ]]; then
  install_sb_shell
else
  echo "Installation cancelled."
fi
