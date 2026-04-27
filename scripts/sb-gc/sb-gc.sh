#!/bin/sh

# Description: This script defines a function called 'gc' that performs a Git commit with a spell-checked and corrected commit message.
# Usage: gc <COMMIT_MESSAGE>
# Parameters:
# - COMMIT_MESSAGE: The commit message to be spell-checked and used for the Git commit.

sb_gc() {
    # Check if a commit message was provided
    if [ $# -eq 0 ] || [ -z "$*" ]; then
        echo "Error: No commit message provided." >&2
        echo "Usage: gc <commit message>" >&2
        return 1
    fi
    
    # Check if git is installed
    if ! command -v git >/dev/null 2>&1; then
        echo "Error: 'git' is not installed. Please install 'git' to use this script." >&2
        return 1
    fi
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "Error: Not in a git repository." >&2
        return 1
    fi
    
    # Initialize message with the provided commit message
    MESSAGE="$*"
    
    # Check if aspell is installed and offer spell checking
    if command -v aspell >/dev/null 2>&1; then
        # Create a secure temporary file
        TEMP_FILE=$(mktemp "${TMPDIR:-/tmp}/gc-spelling.XXXXXX") || {
            echo "Error: Failed to create temporary file." >&2
            return 1
        }

        # Scope the cleanup trap to the aspell window only. EXIT is omitted
        # deliberately: this script is sourced, so an EXIT trap would persist
        # in the user's shell after the function returns.
        trap 'rm -f "$TEMP_FILE"' INT TERM

        echo "$MESSAGE" > "$TEMP_FILE"

        echo "Running spell check..."
        aspell -c "$TEMP_FILE" --dont-backup

        MESSAGE=$(cat "$TEMP_FILE")

        rm -f "$TEMP_FILE"
        trap - INT TERM
        unset TEMP_FILE
    else
        echo "Note: aspell not found, skipping spell check."
        echo "Install aspell for spell-checking functionality."
    fi
    
    # Check if message is empty after spell check (user might have deleted everything)
    if [ -z "$MESSAGE" ]; then
        echo "Error: Commit message is empty after spell check." >&2
        return 1
    fi

    # Display the commit message (with color if terminal supports it)
    echo ""
    echo "Commit message:"
    if [ -t 1 ] && [ "${TERM:-dumb}" != "dumb" ]; then
        printf '\033[32m%s\033[0m\n' "$MESSAGE"
    else
        echo "$MESSAGE"
    fi
    echo ""

    # Prompt the user for confirmation to proceed with the commit
    printf "Do you want to proceed with the commit? (y/n) "
    read -r RESPONSE

    # Check the user's response
    if [ "$RESPONSE" = "y" ] || [ "$RESPONSE" = "Y" ]; then
        echo "Committing changes..."
        if git commit -m "$MESSAGE"; then
            echo "Commit to local repository complete."
        else
            echo "Error: Git commit failed." >&2
            return 1
        fi
    else
        echo "Commit has been cancelled."
    fi
}
