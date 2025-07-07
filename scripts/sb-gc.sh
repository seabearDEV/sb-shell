#!/bin/bash

# Description: This script defines a function called 'gc' that performs a Git commit with a spell-checked and corrected commit message.
# Usage: gc <COMMIT_MESSAGE>
# Parameters:
# - COMMIT_MESSAGE: The commit message to be spell-checked and used for the Git commit.

gc() {
    # Check if aspell is installed
    if ! command -v aspell &> /dev/null; then
        echo "Error: 'aspell' is not installed. Please install 'aspell' to use this script."
        return 1
    fi
    
    # Create a temporary file to store the commit message
    local TEMP_FILE=".check-spelling"

    # Write the commit message to the temporary file
    echo "$1" > "$TEMP_FILE"

    # Use aspell to check and correct the spelling in the temporary file
    aspell -c "$TEMP_FILE" --dont-backup

    # Read the corrected commit message from the temporary file
    local MESSAGE=$(cat "$TEMP_FILE")

    # Remove the temporary file
    rm "$TEMP_FILE"

    # Display the corrected commit message
    echo ""
    echo "Corrected message:"
    echo "\033[32m$MESSAGE\033[0m"
    echo ""

    # Prompt the user for confirmation to proceed with the commit
    echo "Do you want to proceed with the commit? (y/n)"
    read -r RESPONSE

    # Check the user's response
    if [[ "$RESPONSE" == "y" ]]; then
        echo "Committing changes..."
        git commit -m "$MESSAGE"
        echo "Commit to local repository complete."
    else
        echo "Commit has been cancelled."
    fi
}
